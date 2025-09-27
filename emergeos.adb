-- emergeos.adb
with Ada.Text_IO; use Ada.Text_IO;
with System.Memory;

procedure EmergeOS is
   pragma Export (C, EmergeOS, "_Ada_Main");

   -- Test heap allocation
   type Int_Ptr is access Integer;
   X : Int_Ptr;
begin
   Put_Line ("[Ada] EmergeOS kernel started");
   Put_Line ("[Ada] Testing heap allocation...");

   X := new Integer'(42);
   if X /= null then
      Put_Line ("[Ada] Heap allocation successful: " & Integer'Image (X.all));
      Put_Line ("[Ada] EmergeOS Ada kernel BOOTED SUCCESSFULLY!");
   else
      Put_Line ("[Ada] Heap allocation FAILED!");
   end if;

   -- Intentional infinite loop (no exit in kernel)
   loop
      null;
   end loop;
end EmergeOS;
