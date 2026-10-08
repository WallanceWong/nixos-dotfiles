# Printing: CUPS, with printers found automatically — on the network (Avahi,
# driverless IPP Everywhere / AirPrint) and over USB (ipp-usb). Gutenprint
# covers many older printers. "Print Settings" (system-config-printer) to manage.
{ pkgs, ... }:
{
  services.printing = {
    enable = true;
    drivers = [ pkgs.gutenprint ];
    # no cups-browsed: it adds a second, automatic queue for every network
    # printer next to the one set up in Print Settings (the HP showed twice)
    browsed.enable = false;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;      # resolve printer.local names
    openFirewall = true;
  };
  services.ipp-usb.enable = true;
  programs.system-config-printer.enable = true;
}
