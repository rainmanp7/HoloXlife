-- s-memory.ads
with System.Storage_Elements;
package System.Memory is
   use System.Storage_Elements;

   function Allocate (Size : size_t) return Address;
   procedure Deallocate (Addr : Address; Size : size_t);

   pragma Import (C, Allocate, "__gnat_malloc");
   pragma Import (C, Deallocate, "__gnat_free");
end System.Memory;
