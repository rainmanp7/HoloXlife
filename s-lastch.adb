-- s-lastch.adb
with Ada.Text_IO; use Ada.Text_IO;
package body System.Last_Chance_Handler is
   procedure Last_Chance_Handler (Msg : String; Line : Integer) is
   begin
      Put_Line ("[EXCEPTION] Unhandled exception: " & Msg);
      Put_Line ("[EXCEPTION] Line: " & Integer'Image (Line));
      -- Halt
      loop
         null;
      end loop;
   end Last_Chance_Handler;
end System.Last_Chance_Handler;
