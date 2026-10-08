{
	description = "Hyprland on Nixos";
	
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
				};
		};
	
	outputs = {nixpkgs, home-manager, ...}: {
		# nix develop ~/nixos-dotfiles#kernel  /  #osdev  (devshells.nix)
		devShells.x86_64-linux = import ./devshells.nix nixpkgs.legacyPackages.x86_64-linux;

		nixosConfigurations.hyprland-btw = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./configuration.nix
				home-manager.nixosModules.home-manager
				{
					home-manager = {
						useGlobalPkgs = true;
						useUserPackages = true;
						users.Wallance = import ./home.nix;
						backupFileExtension = "backup";
					};
				}
			];
		};
	};
 }

			
