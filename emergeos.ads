-- emergeos.ads - HoloXlife OS Specification
package EmergeOS is
   pragma Export (Assembly, EmergeOS, "emergeos_main");
   pragma No_Return (EmergeOS);
   
   procedure EmergeOS;
end EmergeOS;