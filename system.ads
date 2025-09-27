-- system.ads - Minimal system package for Pure Ada OS
pragma Restrictions (No_Exceptions);
pragma Restrictions (No_Run_Time);

package System is
   pragma Pure;
   pragma No_Elaboration_Code_All;

   type Address is private;
   pragma Preelaborable_Initialization (Address);

   Null_Address : constant Address;

   Storage_Unit : constant := 8;
   Word_Size    : constant := 32;
   Memory_Size  : constant := 2**32;

   type Integer_Address is mod 2**32;
   
   Default_Bit_Order    : constant Bit_Order := Low_Order_First;
   Max_Base_Digits      : constant := 15;
   Max_Digits           : constant := 18;
   
   Min_Int              : constant := -(2**(Standard.Integer'Size - 1));
   Max_Int              : constant := +(2**(Standard.Integer'Size - 1) - 1);
   
   Max_Binary_Modulus   : constant := 2**32;
   Max_Nonbinary_Modulus: constant := 2**31;
   
   type Bit_Order is (High_Order_First, Low_Order_First);
   
private
   type Address is mod 2**32;
   Null_Address : constant Address := 0;
   
end System;

-- System.Machine_Code - Minimal inline assembly support
package System.Machine_Code is
   pragma Pure;
   
   type Asm_Input_Operand is private;
   type Asm_Output_Operand is private;
   
   -- Generic functions for different types
   generic
      type T is private;
   function Generic_Asm_Input (Constraint : String; Value : T) return Asm_Input_Operand;
   
   generic  
      type T is private;
   function Generic_Asm_Output (Constraint : String; Value : T) return Asm_Output_Operand;
   
   -- Specific instantiations for our types
   function Byte_Asm_Input is new Generic_Asm_Input (Byte);
   function Word_Asm_Input is new Generic_Asm_Input (Word);
   function Byte_Asm_Output is new Generic_Asm_Output (Byte);
   
   procedure Asm (Template : String;
                  Outputs  : Asm_Output_Operand := No_Output_Operands;
                  Inputs   : Asm_Input_Operand := No_Input_Operands;
                  Clobber  : String := "";
                  Volatile : Boolean := False);
   pragma Import (Intrinsic, Asm);
   
   No_Output_Operands : constant Asm_Output_Operand;
   No_Input_Operands : constant Asm_Input_Operand;
   
private
   type Asm_Input_Operand is new Integer;
   type Asm_Output_Operand is new Integer;
   
   No_Output_Operands : constant Asm_Output_Operand := 0;
   No_Input_Operands : constant Asm_Input_Operand := 0;
   
end System.Machine_Code;
