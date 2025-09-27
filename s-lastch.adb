-- s-lastch.adb
package body System.Last_Chance_Handler is
   procedure Last_Chance_Handler (Msg : String; Line : Integer) is
   begin
      -- Halt on unhandled exception
      loop
         null;
      end loop;
   end Last_Chance_Handler;
end System.Last_Chance_Handler;
