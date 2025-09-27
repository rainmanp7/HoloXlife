-- s-memory.adb
with System.Storage_Elements;
package body System.Memory is
   use System.Storage_Elements;

   Heap_Start : constant Address := 16#00400000#;  -- 4 MB
   Heap_Size  : constant := 16#00100000#;         -- 1 MB
   Heap_End   : constant Address := Heap_Start + Address (Heap_Size);

   Free_Ptr : Address := Heap_Start;

   function Allocate (Size : size_t) return Address is
      Result : Address := Free_Ptr;
   begin
      if Size = 0 then
         return Null_Address;
      end if;

      -- Align to 4 bytes
      declare
         Aligned_Size : constant size_t := (Size + 3) and 16#FFFFFFFC#;
      begin
         if Free_Ptr + Address (Aligned_Size) > Heap_End then
            return Null_Address;
         end if;
         Free_Ptr := Free_Ptr + Address (Aligned_Size);
      end;

      return Result;
   end Allocate;

   procedure Deallocate (Addr : Address; Size : size_t) is
   begin
      -- Bump allocator: no free list. Ignore.
      null;
   end Deallocate;

end System.Memory;
