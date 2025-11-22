{ lib, ...}:
let
  adguardTeam = {
    filterRegistry = {
      baseUrl = "https://raw.githubusercontent.com/AdguardTeam/FiltersRegistry/master/filters";
      filename = "filter.txt";
    };
    hostlistsRegistry = {
      baseUrl = "https://adguardteam.github.io/HostlistsRegistry/assets";
    };
  };
in [
  "https://yuki2718.github.io/adblock2/japanese/jpf-plus.txt" # Adguard Japanese filter plus
  "https://raw.githubusercontent.com/PepperCat-YamanekoVillage/LINE-Ad-Block/refs/heads/main/list.txt" # LINE Ad Block List
] ++ (lib.forEach [
  "filter_2_Base"
  "filter_3_Spyware"
  "filter_4_Social"
  "filter_5_Experimental"
  "filter_7_Japanese"
  "filter_10_Useful"
  "filter_11_Mobile"
  "filter_14_Annoyances"
  "filter_15_DnsFilter"
  "filter_17_TrackParam"
  "filter_224_Chinese"
] (filter: "${adguardTeam.filterRegistry.baseUrl}/${filter}/${adguardTeam.filterRegistry.filename}"))
  ++ (lib.forEach [
  "filter_1.txt" # DNS filter
  "filter_2.txt" # AdAway default
  "filter_5.txt" # DnsPopupFilter
  "filter_8.txt" # No coin
  "filter_9.txt" # The Big List of Hacked Malware Web Sites
  "filter_10.txt" # ScamBlocklistByDurableNapkin
  "filter_11.txt" # malicious url blocklist
  "filter_24.txt" # 1Hosts Lite
  "filter_27.txt" # 27_OISD_Blocklist_Big
  "filter_30.txt" # Phishing
  "filter_33.txt" # StevenBlack
  "filter_34.txt" # HageziMultiNormal
  "filter_50.txt" # UblockBadwareRisks
  "filter_51.txt" # HageziPro++
] (filter: "${adguardTeam.hostlistsRegistry.baseUrl}/${filter}"))
