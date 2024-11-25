{
  description = "Zenful nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{
	self,
	nix-darwin,
	nixpkgs,
	# nix-homebrew
}:
  let
    configuration = { pkgs, config, ... }: {

	nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs;  [
	# pkgs.alacritty
	pkgs.bruno
	# pkgs.discord
	pkgs.fx
	pkgs.k9s
	pkgs.kubectx
	pkgs.kubelogin
	pkgs.kubernetes-helm
	pkgs.lazygit
	pkgs.mkalias
	pkgs.mkcert
	pkgs.neovim
	pkgs.ngrok
	# pkgs.obsidian
	pkgs.postman
	pkgs.php83
	pkgs.slack
	# pkgs.steam
	pkgs.tea
	pkgs.tmux
	# pkgs.tor
	(pkgs.vscode-with-extensions.override {
		vscodeExtensions = with pkgs.vscode-extensions; [
			bmewburn.vscode-intelephense-client
			esbenp.prettier-vscode
			equinusocio.vsc-material-theme-icons
			vue.volar
		];
	})
	];

	# homebrew = {
	#	enable = true;
	#	brews = [
	#		# Find app ids on the mac app store
	#		"mas"
	#		"nvm"
	#	];
	#	casks = [
	#		"firefox"
	#		"vlc"
	#	];
	#
	#	masApps = {
	#		"Trello" = 1278508951;
	#	};
	#
	#	# Ensure removal of casks not in the list above
	#	onActivation.cleanup = "zap";
	#	onActivation.autoUpdate = true;
	#	onActivation.upgrade = true;
	#};
	
	fonts.packages = [
		(pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
	];

	system.activationScripts.applications.text = let
	env = pkgs.buildEnv {
		name = "system-applications";
		paths = config.environment.systemPackages;
		pathsToLink = "/Applications";
	};
	in
		pkgs.lib.mkForce ''
  		# Set up applications.
  		echo "setting up /Applications..." >&2
  		rm -rf /Applications/Nix\ Apps
  		mkdir -p /Applications/Nix\ Apps
  		find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
  		while read -r src; do
    			app_name=$(basename "$src")
    			echo "copying $src" >&2
    			${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
  		done
		'';

	system.defaults = {
		dock.autohide = true;

		dock.persistent-apps = [
			# "${pkgs.alacritty}/Applications/Alacritty.app"
			"/Applications/Firefox.app"
			"${pkgs.discord}/Applications/Discord.app"
			# "${pkgs.obsidian}/Applications/Obsidian.app"
			"${pkgs.vscode}/Applications/Visual Studio Code.app"
			"/System/Applications/Mail.app"
			"/System/Applications/Calendar.app"
		];

		# https://mynixos.com/nix-darwin/option/system.defaults.finder.FXPreferredViewStyle
		finder.FXPreferredViewStyle = "clmv";
		
		NSGlobalDomain.AppleICUForce24HourTime = true;
	};

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Enable alternative shell support in nix-darwin.
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Remys-MacBook-Pro
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      modules = [
	configuration
	# nix-homebrew.darwinModules.nix-homebrew
	#{
	#	nix-homebrew = {
	#		# Install Homebrew under the default prefix
	#		enable = true;
	#
	#		# Apple Silicon Only
	#		enableRosetta = true;
	#
	#		# User owning the Homebrew prefix
	#		user = "remy";
	#		
	#		# Automatically migrate existing Homebrew installations
	#		autoMigrate = true;
	#	};
	#}
	];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."macbook".pkgs;
  };
}
