-- boot.adb - Pure Ada Bootloader with Minimal Inline Assembly
-- Eliminates kernel_entry.asm by calling EmergeOS directly
with Interfaces;
with System.Storage_Elements;
package body Boot is

   use Interfaces;
   use System.Storage_Elements;
   
   -- Basic types for OS development
   type Byte is mod 2**8;
   type Word is mod 2**16;
   type DWord is mod 2**32;
   
   -- Hardware port I/O using procedure imports (simpler approach)
   procedure Port_Out_8 (Port : Word; Value : Byte);
   pragma Import (C, Port_Out_8, "port_out_8");
   function Port_In_8 (Port : Word) return Byte;
   pragma Import (C, Port_In_8, "port_in_8");
   
   -- ================================
   -- VGA CONSOLE SUBSYSTEM (Pure Ada)
   -- ================================
   type VGA_Color is
     (Black, Blue, Green, Cyan, Red, Magenta, Brown, Light_Gray,
      Dark_Gray, Light_Blue, Light_Green, Light_Cyan, Light_Red,
      Light_Magenta, Yellow, White);
   for VGA_Color use
     (Black => 0, Blue => 1, Green => 2, Cyan => 3, Red => 4,
      Magenta => 5, Brown => 6, Light_Gray => 7, Dark_Gray => 8,
      Light_Blue => 9, Light_Green => 10, Light_Cyan => 11,
      Light_Red => 12, Light_Magenta => 13, Yellow => 14, White => 15);
   type VGA_Entry is record
      Char : Character;
      Attr : Byte;
   end record;
   pragma Pack (VGA_Entry);
   type VGA_Buffer_Type is array (0 .. 24, 0 .. 79) of VGA_Entry;
   VGA_Buffer : VGA_Buffer_Type;
   for VGA_Buffer'Address use System.Storage_Elements.Storage_Address(16#B8000#);
   pragma Import (Ada, VGA_Buffer);
   Console_Row : Natural := 0;
   Console_Col : Natural := 0;
   function Make_Color (FG, BG : VGA_Color) return Byte is
   begin
      return Byte(VGA_Color'Pos(FG)) or (Byte(VGA_Color'Pos(BG)) * 16);
   end Make_Color;
   procedure Console_Clear is
      Color : constant Byte := Make_Color (White, Black);
   begin
      for Row in VGA_Buffer'Range(1) loop
         for Col in VGA_Buffer'Range(2) loop
            VGA_Buffer(Row, Col) := (' ', Color);
         end loop;
      end loop;
      Console_Row := 0;
      Console_Col := 0;
   end Console_Clear;
   procedure Console_Put_Char (C : Character) is
      Color : constant Byte := Make_Color (White, Black);
   begin
      if C = ASCII.LF then -- Line feed
         Console_Col := 0;
         if Console_Row < 24 then
            Console_Row := Console_Row + 1;
         end if;
      elsif C = ASCII.CR then -- Carriage return
         Console_Col := 0;
      else
         if Console_Row < 25 and Console_Col < 80 then
            VGA_Buffer(Console_Row, Console_Col) := (C, Color);
            Console_Col := Console_Col + 1;
            if Console_Col >= 80 then
               Console_Col := 0;
               if Console_Row < 24 then
                  Console_Row := Console_Row + 1;
               end if;
            end if;
         end if;
      end if;
   end Console_Put_Char;
   procedure Console_Put_String (S : String) is
   begin
      for I in S'Range loop
         Console_Put_Char (S(I));
      end loop;
   end Console_Put_String;
   procedure Console_New_Line is
   begin
      Console_Put_Char (ASCII.LF);
   end Console_New_Line;
   
   -- ==============================
   -- DISK LOADING (Pure Ada with Inline Assembly)
   -- ==============================
   procedure Disk_Load (Sector : Word; Count : Word; Buffer : DWord) is
      asm_code : constant String := "
         pusha
         mov bx, 0x1000       # Buffer segment
         mov es, bx
         mov bx, 0x0000       # Buffer offset
         mov ah, 0x02         # Read sectors
         mov al, {Count}      # Number of sectors
         mov ch, 0x00         # Cylinder low
         mov cl, {Sector}     # Sector number
         mov dh, 0x00         # Head number
         mov dl, 0x00         # Drive number (floppy)
         int 0x13             # BIOS disk services
         popa
      ";
   begin
      Asm (asm_code,
           Inputs  => (Count => Count, Sector => Sector),
           Outputs => (Buffer => Buffer),
           Volatile => True);
   end Disk_Load;
   
   -- ==============================
   -- GDT SETUP (Pure Ada with Inline Assembly)
   -- ==============================
   type GDT_Descriptor is record
      Limit : Word;
      Base  : DWord;
   end record;
   pragma Pack (GDT_Descriptor);
   type GDT_Entry is record
      Limit_Low  : Word;
      Base_Low   : Word;
      Base_Mid   : Byte;
      Access     : Byte;
      Granularity: Byte;
      Base_High  : Byte;
   end record;
   pragma Pack (GDT_Entry);
   type GDT_Table is array (0 .. 3) of GDT_Entry;
   pragma Pack (GDT_Table);
   GDT : GDT_Table := (
      (Limit_Low  => 0,
       Base_Low   => 0,
       Base_Mid   => 0,
       Access     => 0,
       Granularity=> 0,
       Base_High  => 0),
      (Limit_Low  => 16#FFFF#, -- 4GB limit
       Base_Low   => 0,
       Base_Mid   => 0,
       Access     => 16#9A#, -- Code segment, present, readable, executable
       Granularity=> 16#CF#, -- 4KB granularity, 32-bit
       Base_High  => 0),
      (Limit_Low  => 16#FFFF#, -- 4GB limit
       Base_Low   => 0,
       Base_Mid   => 0,
       Access     => 16#92#, -- Data segment, present, writable
       Granularity=> 16#CF#, -- 4KB granularity, 32-bit
       Base_High  => 0),
      (Limit_Low  => 0,
       Base_Low   => 0,
       Base_Mid   => 0,
       Access     => 0,
       Granularity=> 0,
       Base_High  => 0));
   GDT_Desc : GDT_Descriptor;
   pragma Import (Ada, GDT_Desc);
   procedure Setup_GDT is
      asm_code : constant String := "
         lgdt ({GDT_Desc})
      ";
   begin
      GDT_Desc.Limit := Word'Pred(GDT'Length * GDT_Entry'Size / 8);
      GDT_Desc.Base  := DWord(GDT'Address);
      Asm (asm_code,
           Inputs  => (GDT_Desc => GDT_Desc),
           Volatile => True);
   end Setup_GDT;
   
   -- ==============================
   -- ENTER PROTECTED MODE (Pure Ada with Inline Assembly)
   -- ==============================
   procedure Enter_Protected_Mode is
      asm_code : constant String := "
         mov eax, cr0
         or eax, 1
         mov cr0, eax
         jmp 0x08:protected_mode
      ";
   begin
      Asm (asm_code,
           Volatile => True);
   end Enter_Protected_Mode;
   
   -- ==============================
   -- PROTECTED MODE CODE (Pure Ada with Inline Assembly)
   -- ==============================
   -- This code sets up stack, clears .bss, and calls EmergeOS directly.
   procedure Protected_Mode_Code is
      asm_code : constant String := "
         [bits 32]
         mov ax, 0x10
         mov ds, ax
         mov ss, ax
         mov es, ax
         mov fs, ax
         mov gs, ax
         mov esp, 0x90000        ; Set up stack at 576KB
         ; Clear BSS section (if __bss_start and __bss_end are defined)
         mov edi, __bss_start
         mov ecx, __bss_end
         sub ecx, edi
         xor eax, eax
         rep stosb
         call emergeos_main       ; Call the main Ada procedure
         jmp $
      ";
   begin
      Asm (asm_code,
           Volatile => True);
   end Protected_Mode_Code;

   procedure Boot is
   begin
      -- ================================
      -- BOOT SEQUENCE
      -- ================================
      -- Phase 1: Hardware Initialization
      Console_Clear;
      Console_Put_String ("Booting...");
      Console_New_Line;
      -- Load kernel from disk
      Disk_Load (Sector => 2, Count => 1, Buffer => 16#10000#);
      -- Setup GDT
      Setup_GDT;
      -- Enter protected mode
      Enter_Protected_Mode;
      -- Call protected mode code (which calls EmergeOS)
      Protected_Mode_Code;
      -- Should never reach here
      loop
         null;
      end loop;
   end Boot;

begin
   null; -- Package body initialization section
end Boot;