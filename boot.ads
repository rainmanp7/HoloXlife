-- boot.ads - HoloXlife Bootloader Specification
package Boot is
   pragma Export (Assembly, Boot, "boot_main");
   pragma No_Return (Boot);
   
   procedure Boot;
end Boot;