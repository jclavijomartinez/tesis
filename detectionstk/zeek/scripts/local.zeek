# scripts/local.zeek
module ARP_DETECTOR;

export {
    redef enum Log::ID += { LOG };
    type Info: record {
        ts: time &log;
        msg: string &log;
        attacker_mac: string &log;
        claimed_ip: addr &log;
    };
}

global seen: table[addr] of string = table();
global mac_claims: table[string] of table[addr] of bool = table();

event zeek_init() {
    Log::create_stream(ARP_DETECTOR::LOG, [$columns=Info, $path="arp_detec"]);
}

event arp_reply(mac_src: string, mac_dst: string, SPA: addr, SHA: string, TPA: addr, THA: string) {
    local prev: string = "";
    if ( SPA in seen ) prev = seen[SPA];

    # 1) IP Change Detection
    if ( prev != "" && prev != SHA ) {
        Log::write(ARP_DETECTOR::LOG, [$ts=network_time(), $msg="IP_MAC_CHANGE", 
                   $attacker_mac=SHA, $claimed_ip=SPA]);
    }
    seen[SPA] = SHA;

    # 2) Many-to-one Detection
    if ( !(SHA in mac_claims) ) mac_claims[SHA] = table();
    mac_claims[SHA][SPA] = T;

    if ( |mac_claims[SHA]| > 1 ) {
        Log::write(ARP_DETECTOR::LOG, [$ts=network_time(), $msg="MANY_TO_ONE_MAC_CLAIM", 
                   $attacker_mac=SHA, $claimed_ip=SPA]);
    }
}
