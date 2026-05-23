{ ... }:

{
  users.users.hello = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # sudo可
  };
}
