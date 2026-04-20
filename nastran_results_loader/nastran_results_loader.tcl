# =============================================================================
# nastran_results_loader.tcl
# MSC Nastran Results File Loader — HyperMesh 2019.1 Aerospace
#
# Kullanım:
#   source nastran_results_loader.tcl
#   NastranResultsLoader::Launch
# =============================================================================

namespace eval NastranResultsLoader {
    variable bdfFile    ""
    variable resultsFile ""
    variable subcaseVar ""
    variable resultTypeVar "Displacement"
    variable statusMsg  "Hazır"
    variable mainWin    ".nastranLoader"

    # Desteklenen sonuç tipleri
    variable resultTypes {
        Displacement
        Stress
        Strain
        Force
        SPC_Force
        MPC_Force
        Grid_Point_Force
        Velocity
        Acceleration
    }

    # Geçerli subcase listesi (id — başlık çiftleri)
    variable subcaseData {}
}

# -----------------------------------------------------------------------------
# Launch — Ana pencereyi aç (zaten açıksa öne getir)
# -----------------------------------------------------------------------------
proc NastranResultsLoader::Launch {} {
    variable mainWin

    if {[winfo exists $mainWin]} {
        wm deiconify $mainWin
        raise $mainWin
        return
    }

    BuildGUI
}

# -----------------------------------------------------------------------------
# BuildGUI — Tüm widget'ları oluşturur ve grid ile düzenler
# -----------------------------------------------------------------------------
proc NastranResultsLoader::BuildGUI {} {
    variable mainWin
    variable bdfFile
    variable resultsFile
    variable subcaseVar
    variable resultTypeVar
    variable statusMsg
    variable resultTypes

    toplevel $mainWin
    wm title $mainWin "MSC Nastran Results File Loader"
    wm resizable $mainWin 0 0

    # ── Başlık ──────────────────────────────────────────────────────────────
    set fTitle [frame $mainWin.fTitle -relief groove -bd 1 -bg #2b4f7a]
    pack $fTitle -fill x -padx 4 -pady 4

    label $fTitle.lTitle \
        -text "MSC Nastran Results File Loader" \
        -font {Helvetica 12 bold} \
        -fg white -bg #2b4f7a \
        -pady 6
    pack $fTitle.lTitle

    label $fTitle.lSub \
        -text "HyperMesh 2019.1 — Aerospace Module" \
        -font {Helvetica 8} \
        -fg #c0d8f0 -bg #2b4f7a \
        -pady 2
    pack $fTitle.lSub

    # ── BDF Dosyası ──────────────────────────────────────────────────────────
    set fBDF [labelframe $mainWin.fBDF -text " 1. Nastran BDF Dosyası " \
        -font {Helvetica 9 bold} -padx 8 -pady 6]
    pack $fBDF -fill x -padx 6 -pady 4

    entry $fBDF.eBDF \
        -textvariable NastranResultsLoader::bdfFile \
        -width 48 -relief sunken
    grid $fBDF.eBDF -row 0 -column 0 -sticky ew -padx {0 4}

    button $fBDF.bBrowse \
        -text "Gözat..." \
        -width 8 \
        -command NastranResultsLoader::BrowseBDF
    grid $fBDF.bBrowse -row 0 -column 1

    button $fBDF.bImport \
        -text "BDF Dosyasını Yükle" \
        -bg #3a7abf -fg white \
        -activebackground #2b5f99 \
        -font {Helvetica 9 bold} \
        -width 22 \
        -command NastranResultsLoader::ImportBDF
    grid $fBDF.bImport -row 1 -column 0 -columnspan 2 -pady {6 0} -sticky ew

    grid columnconfigure $fBDF 0 -weight 1

    # ── Sonuç Dosyası ────────────────────────────────────────────────────────
    set fRes [labelframe $mainWin.fRes -text " 2. Nastran Sonuç Dosyası (.op2) " \
        -font {Helvetica 9 bold} -padx 8 -pady 6]
    pack $fRes -fill x -padx 6 -pady 4

    entry $fRes.eRes \
        -textvariable NastranResultsLoader::resultsFile \
        -width 48 -relief sunken
    grid $fRes.eRes -row 0 -column 0 -sticky ew -padx {0 4}

    button $fRes.bBrowse \
        -text "Gözat..." \
        -width 8 \
        -command NastranResultsLoader::BrowseResults
    grid $fRes.bBrowse -row 0 -column 1

    button $fRes.bLoad \
        -text "Sonuç Dosyasını Yükle" \
        -bg #3a7abf -fg white \
        -activebackground #2b5f99 \
        -font {Helvetica 9 bold} \
        -width 22 \
        -command NastranResultsLoader::LoadResults
    grid $fRes.bLoad -row 1 -column 0 -columnspan 2 -pady {6 0} -sticky ew

    grid columnconfigure $fRes 0 -weight 1

    # ── Subcase ve Result Type ────────────────────────────────────────────────
    set fPost [labelframe $mainWin.fPost -text " 3. Sonuç Uygulama " \
        -font {Helvetica 9 bold} -padx 8 -pady 6]
    pack $fPost -fill x -padx 6 -pady 4

    label $fPost.lSC -text "Load Case (Subcase):"
    grid $fPost.lSC -row 0 -column 0 -sticky w -pady 2

    set NastranResultsLoader::subcaseVar ""
    ttk::combobox $fPost.cbSubcase \
        -textvariable NastranResultsLoader::subcaseVar \
        -state readonly \
        -width 44
    grid $fPost.cbSubcase -row 0 -column 1 -sticky ew -padx {4 0}

    label $fPost.lRT -text "Sonuç Tipi:"
    grid $fPost.lRT -row 1 -column 0 -sticky w -pady 2

    ttk::combobox $fPost.cbType \
        -textvariable NastranResultsLoader::resultTypeVar \
        -values $resultTypes \
        -state readonly \
        -width 44
    grid $fPost.cbType -row 1 -column 1 -sticky ew -padx {4 0}

    button $fPost.bApply \
        -text "Sonuçları Uygula" \
        -bg #2e7d32 -fg white \
        -activebackground #1b5e20 \
        -font {Helvetica 9 bold} \
        -width 22 \
        -command NastranResultsLoader::ApplyResults
    grid $fPost.bApply -row 2 -column 0 -columnspan 2 -pady {8 0} -sticky ew

    grid columnconfigure $fPost 1 -weight 1

    # ── Durum Çubuğu ─────────────────────────────────────────────────────────
    set fStatus [frame $mainWin.fStatus -relief sunken -bd 1 -bg #f0f0f0]
    pack $fStatus -fill x -padx 4 -pady {2 4}

    label $fStatus.lStatus \
        -textvariable NastranResultsLoader::statusMsg \
        -anchor w \
        -bg #f0f0f0 \
        -font {Helvetica 8} \
        -padx 6 -pady 3
    pack $fStatus.lStatus -fill x

    # ── Kapat butonu ─────────────────────────────────────────────────────────
    button $mainWin.bClose \
        -text "Kapat" \
        -width 10 \
        -command [list destroy $mainWin]
    pack $mainWin.bClose -pady {0 6}

    # Pencere ortaya al
    CenterWindow $mainWin
}

# -----------------------------------------------------------------------------
# BrowseBDF — BDF / DAT dosyası seçim diyaloğu
# -----------------------------------------------------------------------------
proc NastranResultsLoader::BrowseBDF {} {
    variable bdfFile

    set types {
        {"Nastran BDF Files" {.bdf .dat .nas .bulk}}
        {"All Files"          *}
    }
    set f [tk_getOpenFile \
        -title    "BDF Dosyası Seç" \
        -filetypes $types \
        -initialdir [GetInitialDir $bdfFile]]

    if {$f ne ""} {
        set bdfFile $f
        SetStatus "BDF dosyası seçildi: [file tail $f]"
    }
}

# -----------------------------------------------------------------------------
# BrowseResults — .op2 (veya .xdb/.h5) dosyası seçim diyaloğu
# -----------------------------------------------------------------------------
proc NastranResultsLoader::BrowseResults {} {
    variable resultsFile

    set types {
        {"Nastran Output2"  {.op2}}
        {"Nastran Database" {.xdb}}
        {"HDF5 Results"     {.h5}}
        {"All Files"         *}
    }
    set f [tk_getOpenFile \
        -title    "Sonuç Dosyası Seç" \
        -filetypes $types \
        -initialdir [GetInitialDir $resultsFile]]

    if {$f ne ""} {
        set resultsFile $f
        SetStatus "Sonuç dosyası seçildi: [file tail $f]"
    }
}

# -----------------------------------------------------------------------------
# ImportBDF — Seçili BDF dosyasını HyperMesh'e import eder
# -----------------------------------------------------------------------------
proc NastranResultsLoader::ImportBDF {} {
    variable bdfFile

    if {$bdfFile eq ""} {
        tk_messageBox -icon warning -title "Uyarı" \
            -message "Lütfen önce bir BDF dosyası seçin." \
            -parent $NastranResultsLoader::mainWin
        return
    }
    if {![file exists $bdfFile]} {
        tk_messageBox -icon error -title "Hata" \
            -message "Dosya bulunamadı:\n$bdfFile" \
            -parent $NastranResultsLoader::mainWin
        return
    }

    SetStatus "BDF dosyası yükleniyor: [file tail $bdfFile] ..."

    # HyperMesh 2019.1 Nastran import komutu
    # Argümanlar: solver template, dosya, import flag'leri
    set rc [catch {
        *feinputwithdata2 "nastran" $bdfFile 0 0 0 0 0 1 0 0
    } err]

    if {$rc != 0} {
        tk_messageBox -icon error -title "Import Hatası" \
            -message "BDF import başarısız:\n$err" \
            -parent $NastranResultsLoader::mainWin
        SetStatus "HATA: BDF import başarısız."
        return
    }

    SetStatus "BDF başarıyla yüklendi: [file tail $bdfFile]"
}

# -----------------------------------------------------------------------------
# LoadResults — Sonuç dosyasını yükler ve subcase listesini doldurur
# -----------------------------------------------------------------------------
proc NastranResultsLoader::LoadResults {} {
    variable resultsFile
    variable subcaseData
    variable mainWin

    if {$resultsFile eq ""} {
        tk_messageBox -icon warning -title "Uyarı" \
            -message "Lütfen önce bir sonuç dosyası seçin." \
            -parent $mainWin
        return
    }
    if {![file exists $resultsFile]} {
        tk_messageBox -icon error -title "Hata" \
            -message "Dosya bulunamadı:\n$resultsFile" \
            -parent $mainWin
        return
    }

    SetStatus "Sonuç dosyası yükleniyor: [file tail $resultsFile] ..."

    # HyperMesh .op2 yükleme komutu
    set rc [catch {
        *post_loadresult $resultsFile
    } err]

    if {$rc != 0} {
        tk_messageBox -icon error -title "Yükleme Hatası" \
            -message "Sonuç dosyası yüklenemedi:\n$err" \
            -parent $mainWin
        SetStatus "HATA: Sonuç yükleme başarısız."
        return
    }

    SetStatus "Sonuç dosyası yüklendi, subcase'ler alınıyor..."
    PopulateSubcases
}

# -----------------------------------------------------------------------------
# PopulateSubcases — Yüklenen sonuçtan subcase listesini doldurur
# -----------------------------------------------------------------------------
proc NastranResultsLoader::PopulateSubcases {} {
    variable subcaseData
    variable subcaseVar
    variable mainWin

    set subcaseData {}
    set labels {}

    # Önce yeni API dene, yoksa eski API'ye düş
    if {[catch {
        set rawList [hm_result getsubcases]
    }]} {
        catch {
            set rawList [hm_getresultsubcases]
        }
    }

    if {![info exists rawList] || $rawList eq ""} {
        SetStatus "Subcase bilgisi alınamadı (sonuç dosyası yüklü mu?)."
        return
    }

    foreach item $rawList {
        # item: {id title} formatında beklenir
        set id    [lindex $item 0]
        set title [lindex $item 1]
        if {$title eq ""} { set title "Subcase $id" }
        lappend subcaseData [list $id $title]
        lappend labels "SC $id — $title"
    }

    # Combobox değerlerini güncelle
    set cb $mainWin.fPost.cbSubcase
    $cb configure -values $labels
    if {[llength $labels] > 0} {
        set subcaseVar [lindex $labels 0]
        SetStatus "[llength $labels] subcase bulundu."
    } else {
        SetStatus "Hiç subcase bulunamadı."
    }
}

# -----------------------------------------------------------------------------
# ApplyResults — Seçili subcase + result type'ı HyperMesh'e uygular
# -----------------------------------------------------------------------------
proc NastranResultsLoader::ApplyResults {} {
    variable subcaseVar
    variable resultTypeVar
    variable subcaseData
    variable mainWin

    if {$subcaseVar eq ""} {
        tk_messageBox -icon warning -title "Uyarı" \
            -message "Lütfen bir Load Case (Subcase) seçin." \
            -parent $mainWin
        return
    }

    # "SC <id> — <title>" etiketinden id'yi çıkar
    set subcaseID ""
    foreach pair $subcaseData {
        set id    [lindex $pair 0]
        set title [lindex $pair 1]
        if {[string match "*SC $id*" $subcaseVar]} {
            set subcaseID $id
            break
        }
    }

    if {$subcaseID eq ""} {
        # Etiket eşleşmesi başarısız, ilk subcase'i kullan
        set subcaseID [lindex [lindex $subcaseData 0] 0]
    }

    SetStatus "Sonuçlar uygulanıyor: Subcase $subcaseID / $resultTypeVar ..."

    set rc [catch {
        hm_result applyresult -subcase $subcaseID -type $resultTypeVar
    } err]

    if {$rc != 0} {
        # Eski API fallback
        catch {
            *post_applyresult $subcaseID $resultTypeVar
        }
    }

    SetStatus "Uygulandı: Subcase $subcaseID — $resultTypeVar"
}

# -----------------------------------------------------------------------------
# Yardımcı prosedürler
# -----------------------------------------------------------------------------
proc NastranResultsLoader::SetStatus {msg} {
    variable statusMsg
    set statusMsg $msg
    update idletasks
}

proc NastranResultsLoader::GetInitialDir {path} {
    if {$path ne "" && [file exists [file dirname $path]]} {
        return [file dirname $path]
    }
    # HyperMesh çalışma dizini
    if {[info exists ::env(HM_CURRENT_DIR)]} {
        return $::env(HM_CURRENT_DIR)
    }
    return [pwd]
}

proc NastranResultsLoader::CenterWindow {w} {
    update idletasks
    set sw [winfo screenwidth  $w]
    set sh [winfo screenheight $w]
    set ww [winfo reqwidth     $w]
    set wh [winfo reqheight    $w]
    set x  [expr {($sw - $ww) / 2}]
    set y  [expr {($sh - $wh) / 2}]
    wm geometry $w "+${x}+${y}"
}
