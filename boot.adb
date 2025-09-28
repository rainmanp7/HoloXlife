-- boot.adb - Pure Ada Bootloader with Fixed Issues
with Interfaces;
with System.Storage_Elements;
with System.Machine_Code;

procedure Boot is
   use Interfaces;
   use System.Storage_Elements;
   use System.Machine_Code;

   -- Basic types for OS development
   type Byte is mod 2**8;
   type Word is mod 2**16;
   type DWord is mod 2**32;

   -- VGA CONSOLE SUBSYSTEM (Pure Ada)
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
   for VGA_Buffer'Address use System.Storage_Elements.To_Address(16#B8000#);
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
      if C = ASCII.LF then
         Console_Col := 0;
         if Console_Row < 24 then
            Console_Row := Console_Row + 1;
         end if;
      elsif C = ASCII.CR then
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

   -- GDT SETUP (Pure Ada)
   type GDT_Entry is record
      Limit_Low   : Word;
      Base_Low    : Word;
      Base_Mid    : Byte;
      Access_Byte : Byte;
      Granularity : Byte;
      Base_High   : Byte;
   end record;
   pragma Pack (GDT_Entry);

   type GDT_Pointer is record
      Limit : Word;
      Base  : DWord;
   end record;
   pragma Pack (GDT_Pointer);

   -- GDT with null, code, and data segments
   GDT : array (0 .. 2) of GDT_Entry := (
      -- Null segment
      0 => (Limit_Low   => 0,
            Base_Low    => 0,
            Base_Mid    => 0,
            Access_Byte => 0,
            Granularity => 0,
            Base_High   => 0),
      -- Code segment (base=0, limit=4GB, present, ring 0, executable, readable)
      1 => (Limit_Low   => 16#FFFF#,
            Base_Low    => 0,
            Base_Mid    => 0,
            Access_Byte => 16#9A#,  -- Present, Ring 0, Code, Execute/Read
            Granularity => 16#CF#,  -- 4KB granularity, 32-bit, limit[19:16]=F
            Base_High   => 0),
      -- Data segment (base=0, limit=4GB, present, ring 0, writable)
      2 => (Limit_Low   => 16#FFFF#,
            Base_Low    => 0,
            Base_Mid    => 0,
            Access_Byte => 16#92#,  -- Present, Ring 0, Data, Read/Write
            Granularity => 16#CF#,  -- 4KB granularity, 32-bit, limit[19:16]=F
            Base_High   => 0));

   GDT_Ptr : GDT_Pointer;

   procedure Setup_GDT is
   begin
      GDT_Ptr.Limit := Word(GDT'Size / 8 - 1);
      GDT_Ptr.Base  := DWord(Integer_Address(GDT'Address));

      -- Load GDT using inline assembly
      Asm (Template => "lgdt %0",
           Inputs   => System.Machine_Code.C_Type'Asm_Input ("m", GDT_Ptr),
           Volatile => True);
   end Setup_GDT;

   -- ENTER PROTECTED MODE
   procedure Enter_Protected_Mode is
   begin
      -- Enable protected mode by setting CR0.PE bit
      Asm (Template => "movl %%cr0, %%eax" & ASCII.LF &
                       "orl $1, %%eax" & ASCII.LF &
                       "movl %%eax, %%cr0" & ASCII.LF &
                       "ljmp $0x08, $1f" & ASCII.LF &
                       "1: movw $0x10, %%ax" & ASCII.LF &
                       "movw %%ax, %%ds" & ASCII.LF &
                       "movw %%ax, %%es" & ASCII.LF &
                       "movw %%ax, %%fs" & ASCII.LF &
                       "movw %%ax, %%gs" & ASCII.LF &
                       "movw %%ax, %%ss",
           Clobber  => "eax",
           Volatile => True);
   end Enter_Protected_Mode;

   -- Simple kernel stub (since EmergeOS package is not available)
   procedure Kernel_Main is
   begin
      Console_Put_String ("Kernel loaded successfully!");
      Console_New_Line;
      Console_Put_String ("System ready.");
      Console_New_Line;
   end Kernel_Main;

begin
   -- Initialize console
   Console_Clear;
   Console_Put_String ("HoloXlife Pure Ada OS");
   Console_New_Line;
   Console_Put_String ("Initializing GDT...");
   Console_New_Line;

   -- Setup GDT and enter protected mode
   Setup_GDT;
   Console_Put_String ("GDT loaded. Entering protected mode...");
   Console_New_Line;
   
   Enter_Protected_Mode;
   
   -- Call kernel main
   Kernel_Main;

   -- Halt system
   Console_Put_String ("System halted.");
   Console_New_Line;
   
   -- Infinite loop
   loop
      Asm (Template => "hlt", Volatile => True);
   end loop;
end Boot;
