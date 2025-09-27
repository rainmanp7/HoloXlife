-- emergeos.adb - Main Ada kernel (replaces holographic_kernel.c)
with System;
with System.Storage_Elements;
with System.Machine_Code;

procedure EmergeOS is
   pragma Export (C, EmergeOS, "kmain");
   pragma No_Return (EmergeOS);
   
   -- Memory constants
   VIDEO_MEMORY : constant System.Address := System.Storage_Elements.To_Address(16#B8000#);
   KERNEL_HEAP_SIZE : constant := 16#40000#; -- 256KB
   
   -- Types
   type Uint8 is range 0 .. 255;
   for Uint8'Size use 8;
   
   type Uint32 is range 0 .. 2**32 - 1;
   for Uint32'Size use 32;
   
   type Kernel_Heap is array (0 .. KERNEL_HEAP_SIZE - 1) of Uint8;
   pragma Pack (Kernel_Heap);
   
   -- Global variables
   Kernel_Memory : Kernel_Heap;
   pragma Export (C, Kernel_Memory, "kernel_heap");
   
   Heap_Offset : Uint32 := 0;
   Screen_Position : Natural := 0;
   
   -- Simple memory allocator
   function Kmalloc (Size : Uint32) return System.Address is
      use System.Storage_Elements;
      Aligned_Size : constant Uint32 := (Size + 7) and not 7; -- 8-byte align
   begin
      if Heap_Offset + Aligned_Size > KERNEL_HEAP_SIZE then
         return System.Null_Address;
      end if;
      
      declare
         Ptr : constant System.Address := 
            Kernel_Memory(Natural(Heap_Offset))'Address;
      begin
         Heap_Offset := Heap_Offset + Aligned_Size;
         return Ptr;
      end;
   end Kmalloc;
   
   -- VGA text output
   procedure Print (Str : String) is
      use System.Storage_Elements;
      VGA_Buffer : array (0 .. 3999) of Uint8;
      for VGA_Buffer'Address use VIDEO_MEMORY;
      pragma Import (C, VGA_Buffer);
   begin
      for I in Str'Range loop
         if Str(I) = ASCII.LF then  -- newline
            Screen_Position := (Screen_Position / 80 + 1) * 80;
         else
            if Screen_Position < 2000 then -- 80x25 screen = 2000 characters
               VGA_Buffer(Screen_Position * 2) := Character'Pos(Str(I));
               VGA_Buffer(Screen_Position * 2 + 1) := 16#0F#; -- White on black
               Screen_Position := Screen_Position + 1;
            end if;
         end if;
         
         -- Handle screen scrolling
         if Screen_Position >= 2000 then
            -- Scroll up: copy 24 lines (1920 chars) up by one line (160 bytes)
            for J in 0 .. 1919 loop
               VGA_Buffer(J * 2) := VGA_Buffer((J + 80) * 2);
               VGA_Buffer(J * 2 + 1) := VGA_Buffer((J + 80) * 2 + 1);
            end loop;
            
            -- Clear bottom line
            for J in 1920 .. 1999 loop
               VGA_Buffer(J * 2) := Character'Pos(' ');
               VGA_Buffer(J * 2 + 1) := 16#0F#;
            end loop;
            
            Screen_Position := 1920; -- Position at start of last line
         end if;
      end loop;
   end Print;
   
   -- Halt instruction wrapper
   procedure Halt_CPU is
   begin
      System.Machine_Code.Asm ("hlt", Volatile => True);
   end Halt_CPU;
   
begin
   -- Initialize screen position
   Screen_Position := 0;
   
   -- Main kernel entry point - display boot messages
   Print ("=== EMERGEOS ADA BOOTED ===" & ASCII.LF);
   Print ("SUCCESS: Ada Kernel is running!" & ASCII.LF);
   Print ("Heap: 256KB (safe)" & ASCII.LF);
   Print ("Stack: 0x90000 (safe)" & ASCII.LF);
   Print ("Language: Ada 2012" & ASCII.LF);
   Print ("Memory allocator: Ready" & ASCII.LF);
   
   -- Main kernel loop - halt forever
   loop
      Halt_CPU;
   end loop;
   
end EmergeOS;