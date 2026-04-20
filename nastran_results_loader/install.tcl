# =============================================================================
# install.tcl
# MSC Nastran Results File Loader — HyperMesh 2019.1 Menü Entegrasyonu
#
# Kurulum:
#   Bu dosyayı HyperMesh başlangıç script klasörüne kopyalayın:
#     $ALTAIR_HOME/scripts/  (tüm kullanıcılar için)
#   veya kullanıcı profil klasörüne:
#     %APPDATA%/Altair/2019.1/hm/scripts/  (Windows)
#     ~/.altair/2019.1/hm/scripts/          (Linux)
#
#   HyperMesh başladığında bu dosya otomatik olarak çalışır.
#   Alternatif olarak el ile yüklemek için HyperMesh komut satırına:
#     source {/tam/yol/install.tcl}
# =============================================================================

# Loader script'in bulunduğu dizini belirle
set _nrl_dir [file dirname [file normalize [info script]]]
set _nrl_script [file join $_nrl_dir nastran_results_loader.tcl]

# Ana tool script'ini source et
if {[file exists $_nrl_script]} {
    source $_nrl_script
} else {
    error "nastran_results_loader.tcl bulunamadı: $_nrl_script"
}

# -----------------------------------------------------------------------------
# HyperMesh Tools menüsüne girdi ekle
# -----------------------------------------------------------------------------
proc _NRL_AddMenu {} {
    global _nrl_script

    # *menuinsert HyperMesh 2019.1'de Tools menüsüne öğe ekler
    if {[catch {
        *menuinsert "Tools" "Nastran Results Loader..." {
            NastranResultsLoader::Launch
        }
    } err]} {
        # Menü entegrasyonu başarısız olsa bile tool doğrudan çağrılabilir:
        #   NastranResultsLoader::Launch
        puts "Nastran Results Loader menü entegrasyonu atlandı: $err"
        puts "Tool'u doğrudan çağırmak için: NastranResultsLoader::Launch"
    }
}

# HyperMesh başlatma sonrasında menüye ekle
# *afterHMStart varsa kullan, yoksa doğrudan çalıştır
if {[llength [info commands *afterHMStart]] > 0} {
    *afterHMStart {_NRL_AddMenu}
} else {
    _NRL_AddMenu
}

puts "MSC Nastran Results File Loader yüklendi."
puts "Başlatmak için: NastranResultsLoader::Launch"
