-- system.ads - Pure Ada OS System Package
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

   -- Pure Ada OS configuration
   type Integer_Address is mod 2**32;
   
   Default_Bit_Order    : constant Bit_Order := Low_Order_First;
   Max_Base_Digits      : constant := 15;
   Max_Digits           : constant := 18;
   
   Min_Int              : constant := -(2**(Standard.Integer'Size - 1));
   Max_Int              : constant := +(2**(Standard.Integer'Size - 1) - 1);
   
   Max_Binary_Modulus   : constant := 2**32;
   Max_Nonbinary_Modulus: constant := 2**31;
   
   -- Hardware abstraction for Pure Ada OS
   type Bit_Order is (High_Order_First, Low_Order_First);
   
private
   type Address is mod 2**32;
   Null_Address : constant Address := 0;
   
end System;


-- System.Machine_Code - For inline assembly in Pure Ada
package System.Machine_Code is
   pragma Pure;
   
   type Asm_Input_Operand is private;
   type Asm_Output_Operand is private;
   
   function Asm_Input (Constraint : String; Value : Integer) return Asm_Input_Operand;
   function Asm_Output (Constraint : String; Value : Integer) return Asm_Output_Operand;
   
   generic
      type T is private;
   function Generic_Asm_Input (Constraint : String; Value : T) return Asm_Input_Operand;
   
   generic  
      type T is private;
   function Generic_Asm_Output (Constraint : String; Value : T) return Asm_Output_Operand;
   
   procedure Asm (Template : String;
                  Outputs  : Asm_Output_Operand := No_Output_Operands;
                  Inputs   : Asm_Input_Operand := No_Input_Operands;
                  Clobber  : String := "";
                  Volatile : Boolean := False);
   
   No_Output_Operands : constant Asm_Output_Operand;
   No_Input_Operands : constant Asm_Input_Operand;
   
private
   type Asm_Input_Operand is new Integer;
   type Asm_Output_Operand is new Integer;
   
   No_Output_Operands : constant Asm_Output_Operand := 0;
   No_Input_Operands : constant Asm_Input_Operand := 0;
   
end System.Machine_Code;
