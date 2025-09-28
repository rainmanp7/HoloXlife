-- emergeos.ads - HoloXlife OS Specification
package EmergeOS is
   procedure EmergeOS;
   pragma Export (Assembly, EmergeOS, "emergeos_main");
   pragma No_Return (EmergeOS);
end EmergeOS;
