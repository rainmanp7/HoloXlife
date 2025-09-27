-- system.ads
pragma Compiler_Unit_Warning;

package System is
   pragma Pure;

   type Address is private;
   pragma Preelaborable_Initialization (Address);

   Null_Address : constant Address;

   type Integer_Address is mod 2**32;
   type Address is mod 2**32;
   Null_Address : constant Address := 0;

   Storage_Unit : constant := 8;
   Word_Size    : constant := 32;
   Memory_Size  : constant := 2**32;

   -- No elaboration code
   pragma No_Elaboration_Code_All;
end System;
