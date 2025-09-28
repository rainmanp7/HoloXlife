-- system.ads - Minimal system package for Pure Ada OS
package System is
   pragma Pure;

   type Address is private;
   pragma Preelaborable_Initialization (Address);

   Null_Address : constant Address;

   Storage_Unit : constant := 8;
   Word_Size    : constant := 32;
   Memory_Size  : constant := 2**32;

   type Integer_Address is mod 2**32;
   
   type Bit_Order is (High_Order_First, Low_Order_First);
   Default_Bit_Order : constant Bit_Order := Low_Order_First;
   
   Max_Base_Digits       : constant := 15;
   Max_Digits            : constant := 18;
   
   Min_Int               : constant := -(2**(Standard.Integer'Size - 1));
   Max_Int               : constant := +(2**(Standard.Integer'Size - 1) - 1);
   
   Max_Binary_Modulus    : constant := 2**32;
   Max_Nonbinary_Modulus : constant := 2**31;
   
   -- Priority range
   type Any_Priority is new Integer range 0 .. 31;
   type Priority is new Any_Priority range 0 .. 30;
   type Interrupt_Priority is new Any_Priority range 31 .. 31;
   
   Default_Priority : constant Priority := 15;

private
   type Address is mod 2**32;
   Null_Address : constant Address := 0;
   
end System;
