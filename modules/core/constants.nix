let
  localhost = "127.0.0.1:";
  #socksUri = "socks5h://"; # H param to use remote DNS
  socksUri = "socks5://";
  #
  Promux1Port = "8001";
  Promux1Addr = localhost + Promux1Port;
  Promux1Socks = socksUri + Promux1Addr;
  #
  Promux2Port = "8002";
  Promux2Addr = localhost + Promux2Port;
  Promux2Socks = socksUri + Promux2Addr;
  #
  TorPort = "9050";
  TorAddr = localhost + TorPort;
  TorSocks = socksUri + TorAddr;
  #                               +-----------+
  #               +---------+ +-->+ Ygg Proxy |
  #          +--->+ Promux1 +-|-+>+-----------+
  #      +---+-+  +---------+ | |
  #      | Tor +<-----+       | | 
  #      +-----+  +---+-----+ | | +-------------+
  #  +-----+  +-->+ Promux2 +-+ +>+ Local Socks |
  #  | git +--+   +---------+     +-------------+
  #  +-----+
in
{
  inherit 
    localhost
    socksUri
    Promux1Port
    Promux1Addr
    Promux1Socks
    Promux2Port
    Promux2Addr
    Promux2Socks
    TorPort
    TorAddr
    TorSocks;
}
