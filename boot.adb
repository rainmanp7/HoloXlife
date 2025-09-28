-- boot.adb - Pure Ada Bootloader with Correct Inline Assembly and Fixed Issues
with Interfaces;
with System.Storage_Elements;
with System.Machine_Code;
with EmergeOS;  -- Import kernel package

procedure Boot is
   use Interfaces;
   use System.Storage_Elements;
   use System.Machine_Code;

   -- Basic types for OS development
   type Byte is mod 2**8;
   type Word is mod 2**16;
   type DWord is mod 2**32;

   -- Hardware port I/O using procedure imports
   procedure Port_Out_8 (Port : Word; Value : Byte);
   pragma Import (C, Port_Out_8, "port_out_8");
   function Port_In_8 (Port : Word) return Byte;
   pragma Import (C, Port_In_8, "port_in_8");

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
   type GDT_Descriptor is record
      Limit : Word;
      Base  : DWord;
   end record;
   pragma Pack (GDT_Descriptor);

   type GDT_Entry is record
      Limit_Low  : Word;
      Base_Low   : Word;
      Base_Mid   : Byte;
      Access_Bit : Byte;
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
       Access_Bit => 0,
       Granularity=> 0,
       Base_High  => 0),
      (Limit_Low  => 16#FFFF#,
       Base_Low   => 0,
       Base_Mid   => 0,
       Access_Bit => 16#9A#,
       Granularity=> 16#CF#,
       Base_High  => 0),
      (Limit_Low  => 16#FFFF#,
       Base_Low   => 0,
       Base_Mid   => 0,
       Access_Bit => 16#92#,
       Granularity=> 16#CF#,
       Base_High  => 0),
      (Limit_Low  => 0,
       Base_Low   => 0,
       Base_Mid   => 0,
       Access_Bit => 0,
       Granularity=> 0,
       Base_High  => 0));

   GDT_Desc : GDT_Descriptor;

   procedure Setup_GDT is
      Size_In_Bytes : constant Natural := (GDT'Length * GDT_Entry'Size) / 8;
   begin
      GDT_Desc.Limit := Word'Pred(Size_In_Bytes);
      GDT_Desc.Base  := DWord(GDT'Address);

      -- Inline assembly to load GDT
      asm (
         "lgdt (%0)"
         :
         : "r" (GDT_Desc)
         : "memory"
      );
   end Setup_GDT;

   -- ENTER PROTECTED MODE
   procedure Enter_Protected_Mode is
   begin
      asm (
         "mov %%cr0, %%eax\n\t"
         "or $1, %%eax\n\t"
         "mov %%eax, %%cr0\n\t"
         "jmp $0x08, $1f\n\t"
         "1:"
         :
         :
         : "eax", "memory"
      );
   end Enter_Protected_Mode;

begin
   Console_Clear;
   Console_Put_String ("Booting HoloXlife Pure Ada OS...");
   Console_New_Line;

   Setup_GDT;
   Enter_Protected_Mode;

   -- Call the kernel main procedure explicitly
   EmergeOS.EmergeOS;

   -- Infinite loop if kernel returns
   loop
      null;
   end loop;
end Boot;
