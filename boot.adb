-- boot.adb - Pure Ada Bootloader (No Inline Assembly Version)
with Interfaces;
with System.Storage_Elements;

procedure Boot is
   use Interfaces;
   use System.Storage_Elements;

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
      Color : constant Byte := Make_Color (Light_Green, Black);
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

   -- External kernel entry point
   procedure EmergeOS_Main;
   pragma Import (C, EmergeOS_Main, "emergeos_main");

begin
   -- Initialize console
   Console_Clear;
   Console_Put_String ("HoloXlife OS v1.0 - Pure Ada Implementation");
   Console_New_Line;
   Console_Put_String ("Bootloader: Ada Runtime Initialized");
   Console_New_Line;
   Console_Put_String ("System: Starting kernel...");
   Console_New_Line;

   -- Call the main kernel procedure
   EmergeOS_Main;

   -- If kernel returns, halt
   Console_Put_String ("System: Kernel returned - halting");
   Console_New_Line;
   
   -- Infinite loop
   loop
      null;
   end loop;
end Boot;