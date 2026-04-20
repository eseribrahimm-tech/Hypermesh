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

    # 1D element yük çıkarımı
    variable elem1DTypeVar   "Bar Forces"
    variable elem1DTypes     {"Bar Forces" "Beam Forces" "Rod Forces" \
                              "Bush Forces" "Gap Forces" "Weld Forces"}
    variable loadsOutputFile ""
    variable extractedLoads  {}
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
    variable elem1DTypeVar
    variable elem1DTypes
    variable loadsOutputFile

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

    # ── 1D Element Yük Çıkarımı ─────────────────────────────────────────────
    set fExtr [labelframe $mainWin.fExtr \
        -text " 4. 1D Element Yük Çıkarımı " \
        -font {Helvetica 9 bold} -padx 8 -pady 6]
    pack $fExtr -fill x -padx 6 -pady 4

    label $fExtr.lType -text "Sonuç Tipi:"
    grid $fExtr.lType -row 0 -column 0 -sticky w -pady 2

    ttk::combobox $fExtr.cbType \
        -textvariable NastranResultsLoader::elem1DTypeVar \
        -values       $elem1DTypes \
        -state readonly \
        -width 44
    grid $fExtr.cbType -row 0 -column 1 -sticky ew -padx {4 0}

    label $fExtr.lParams \
        -text "Corners: Kapalı  |  Avg Yöntemi: None  |  Sistem: Elemental" \
        -font {Helvetica 8 italic} \
        -fg #555555
    grid $fExtr.lParams -row 1 -column 0 -columnspan 2 -sticky w -pady {2 4}

    frame $fExtr.fOut
    grid $fExtr.fOut -row 2 -column 0 -columnspan 2 -sticky ew -pady {0 4}

    label $fExtr.fOut.lFile -text "CSV Çıktısı (opsiyonel):"
    pack $fExtr.fOut.lFile -side left

    entry $fExtr.fOut.eFile \
        -textvariable NastranResultsLoader::loadsOutputFile \
        -width 28 -relief sunken
    pack $fExtr.fOut.eFile -side left -expand 1 -fill x -padx {4 4}

    button $fExtr.fOut.bBrowse \
        -text "Gözat..." \
        -width 8 \
        -command NastranResultsLoader::BrowseOutputFile
    pack $fExtr.fOut.bBrowse -side left

    button $fExtr.bExtract \
        -text "1D Element Yüklerini Çıkar" \
        -bg #7b3f00 -fg white \
        -activebackground #5a2d00 \
        -font {Helvetica 9 bold} \
        -command NastranResultsLoader::Extract1DElementLoads
    grid $fExtr.bExtract -row 3 -column 0 -columnspan 2 -pady {0 2} -sticky ew

    grid columnconfigure $fExtr 1 -weight 1

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

# -----------------------------------------------------------------------------
# BrowseOutputFile — CSV çıktı dosyası kayıt diyaloğu
# -----------------------------------------------------------------------------
proc NastranResultsLoader::BrowseOutputFile {} {
    variable loadsOutputFile

    set types {
        {"CSV Dosyası"   {.csv}}
        {"Metin Dosyası" {.txt}}
        {"Tüm Dosyalar"   *}
    }
    set f [tk_getSaveFile \
        -title            "CSV Çıktı Dosyası Seç" \
        -filetypes        $types \
        -defaultextension ".csv" \
        -initialdir       [GetInitialDir $loadsOutputFile]]

    if {$f ne ""} {
        set loadsOutputFile $f
        SetStatus "CSV çıktı dosyası: [file tail $f]"
    }
}

# -----------------------------------------------------------------------------
# GetSubcaseID — Seçili subcase etiketinden numerik ID döndürür
# -----------------------------------------------------------------------------
proc NastranResultsLoader::GetSubcaseID {} {
    variable subcaseVar
    variable subcaseData

    if {$subcaseVar eq "" || [llength $subcaseData] == 0} {
        return ""
    }
    foreach pair $subcaseData {
        set id [lindex $pair 0]
        if {[string match "*SC $id*" $subcaseVar]} {
            return $id
        }
    }
    return [lindex [lindex $subcaseData 0] 0]
}

# -----------------------------------------------------------------------------
# Get1DElements — Modeldeki tüm 1D element ID'lerini döndürür
# -----------------------------------------------------------------------------
proc NastranResultsLoader::Get1DElements {} {
    set cfgs1D {cbar cbeam crod ctube conrod cbush cgap cweld crbe2 crbe3}
    set elemIDs {}

    # Yöntem 1: config bazlı toplu mark
    set rc [catch {
        eval [list *createmark elems 1 "by config"] $cfgs1D
        set elemIDs [hm_getmark elems 1]
    }]

    # Yöntem 2: tüm elementleri al, config alanına göre filtrele
    if {$rc != 0 || [llength $elemIDs] == 0} {
        set elemIDs {}
        catch {
            *createmark elems 1 "all"
            foreach eid [hm_getmark elems 1] {
                catch {
                    set cfg [string tolower [hm_getvalue elem id=$eid dataname=config]]
                    if {[lsearch -exact $cfgs1D $cfg] >= 0} {
                        lappend elemIDs $eid
                    }
                }
            }
        }
    }

    # Yöntem 3: HyperMesh element-tip markeri
    if {[llength $elemIDs] == 0} {
        catch {
            *elementtypemark elems 1 "1d"
            set elemIDs [hm_getmark elems 1]
        }
    }

    return $elemIDs
}

# -----------------------------------------------------------------------------
# Extract1DElementLoads — Ana çıkarım prosedürü
# Sabit parametreler: Corners=False  AvgMethod=None  System=Elemental
# -----------------------------------------------------------------------------
proc NastranResultsLoader::Extract1DElementLoads {} {
    variable elem1DTypeVar
    variable loadsOutputFile
    variable extractedLoads
    variable mainWin

    set subcaseID [GetSubcaseID]
    if {$subcaseID eq ""} {
        tk_messageBox -icon warning -title "Uyarı" \
            -message "Lütfen önce sonuç dosyasını yükleyin ve bir subcase seçin." \
            -parent $mainWin
        return
    }

    SetStatus "1D elementler aranıyor..."
    set elemIDs [Get1DElements]

    if {[llength $elemIDs] == 0} {
        tk_messageBox -icon warning -title "1D Element Bulunamadı" \
            -message "Modelde 1D element (CBAR, CBEAM, CROD vb.) bulunamadı.\nÖnce BDF dosyasını yükleyin." \
            -parent $mainWin
        SetStatus "1D element bulunamadı."
        return
    }

    SetStatus "SC $subcaseID — $elem1DTypeVar sorgulanıyor ([llength $elemIDs] element)..."

    set extractedLoads {}
    set queryErr "Tüm API yöntemleri başarısız."

    # Yöntem 1: hm_getresultvalues (modern HM API)
    if {[catch {
        set raw [hm_getresultvalues \
            -subcase   $subcaseID \
            -type      $elem1DTypeVar \
            -system    "Elemental" \
            -averaging "None" \
            -corners   0 \
            -entity    "elems" \
            -ids       $elemIDs]
        set extractedLoads [ParseQueryResult $raw $elemIDs]
    } queryErr]} {

        # Yöntem 2: hm_result query (alternatif modern API)
        if {[catch {
            set raw [hm_result query \
                -subcase   $subcaseID \
                -type      $elem1DTypeVar \
                -system    "Elemental" \
                -averaging "None" \
                -corners   0 \
                -entities  "elems" \
                -ids       $elemIDs]
            set extractedLoads [ParseQueryResult $raw $elemIDs]
        } queryErr]} {

            # Yöntem 3: applyresult + hm_getvalue (legacy element-by-element)
            catch {
                set applyErr ""
                if {[catch {
                    hm_result applyresult \
                        -subcase   $subcaseID \
                        -type      $elem1DTypeVar \
                        -system    "Elemental" \
                        -averaging "None" \
                        -corners   0
                } applyErr]} {
                    *post_applyresult $subcaseID $elem1DTypeVar
                }

                set tmp {}
                foreach eid $elemIDs {
                    set row [list EID $eid]
                    foreach comp {X Y Z Mag} {
                        set val "N/A"
                        catch { set val [hm_getvalue elem id=$eid dataname=Result$comp] }
                        if {$val eq "N/A"} {
                            catch { set val [hm_getvalue elem id=$eid dataname=$comp] }
                        }
                        lappend row $comp $val
                    }
                    lappend tmp $row
                }
                if {[llength $tmp] > 0} {
                    set extractedLoads $tmp
                    set queryErr ""
                }
            }
        }
    }

    if {[llength $extractedLoads] == 0} {
        tk_messageBox -icon error -title "Sorgu Hatası" \
            -message "1D element yükleri alınamadı.\n\n$queryErr\n\nSonuç dosyasının yüklü ve subcase seçili olduğundan emin olun." \
            -parent $mainWin
        SetStatus "HATA: 1D yük çıkarımı başarısız."
        return
    }

    SetStatus "[llength $extractedLoads] element için yük alındı — SC $subcaseID / $elem1DTypeVar"
    ShowExtractedLoads $extractedLoads $subcaseID

    if {$loadsOutputFile ne ""} {
        ExportLoadsToCSV $subcaseID
    }
}

# -----------------------------------------------------------------------------
# ParseQueryResult — API ham verisini standart {EID x X x Y x Z x Mag x} listesine çevirir
# -----------------------------------------------------------------------------
proc NastranResultsLoader::ParseQueryResult {rawData elemIDs} {
    if {$rawData eq "" || $rawData eq {}} { return {} }

    set results {}

    # Format 1: liste elemanları {elemID {comp val ...}} çiftiyse
    set first [lindex $rawData 0]
    if {[llength $first] == 2 && [llength [lindex $first 1]] > 1} {
        foreach item $rawData {
            set eid  [lindex $item 0]
            set vals [lindex $item 1]
            set row  [list EID $eid]
            foreach {comp val} $vals { lappend row $comp $val }
            lappend results $row
        }
        return $results
    }

    # Format 2: düz sayı dizisi — elemIDs ile stride'a böl
    set nElems [llength $elemIDs]
    set nVals  [llength $rawData]
    if {$nElems == 0} { return {} }
    set stride [expr {$nVals / $nElems}]
    if {$stride < 1} { set stride 1 }

    set i 0
    foreach eid $elemIDs {
        set off [expr {$i * $stride}]
        set row [list EID $eid]
        foreach comp {X Y Z Mag} idx {0 1 2 3} {
            set vidx [expr {$off + $idx}]
            lappend row $comp [expr {$vidx < $nVals ? [lindex $rawData $vidx] : "N/A"}]
        }
        lappend results $row
        incr i
    }
    return $results
}

# -----------------------------------------------------------------------------
# ShowExtractedLoads — Sonuçları tablo penceresinde gösterir
# -----------------------------------------------------------------------------
proc NastranResultsLoader::ShowExtractedLoads {data subcaseID} {
    variable elem1DTypeVar
    variable loadsOutputFile

    set w ".loads1DResult"
    if {[winfo exists $w]} { destroy $w }

    toplevel $w
    wm title $w "1D Element Yükleri — SC $subcaseID / $elem1DTypeVar"
    wm resizable $w 1 1

    label $w.lHdr \
        -text "SC $subcaseID  |  $elem1DTypeVar  |  Sistem: Elemental  |  Corners: Kapalı  |  Avg: None" \
        -font {Helvetica 9 bold} -bg #2b4f7a -fg white -padx 8 -pady 4
    pack $w.lHdr -fill x

    frame $w.fTbl
    pack $w.fTbl -fill both -expand 1 -padx 4 -pady 4

    text $w.fTbl.txt \
        -width 72 -height 28 \
        -font {Courier 9} \
        -yscrollcommand [list $w.fTbl.sb set] \
        -xscrollcommand [list $w.fTbl.sbx set]
    scrollbar $w.fTbl.sb  -orient vertical   -command [list $w.fTbl.txt yview]
    scrollbar $w.fTbl.sbx -orient horizontal -command [list $w.fTbl.txt xview]

    grid $w.fTbl.txt -row 0 -column 0 -sticky nsew
    grid $w.fTbl.sb  -row 0 -column 1 -sticky ns
    grid $w.fTbl.sbx -row 1 -column 0 -sticky ew
    grid rowconfigure    $w.fTbl 0 -weight 1
    grid columnconfigure $w.fTbl 0 -weight 1

    set hdr [format "%-10s  %16s  %16s  %16s  %16s" ElemID X Y Z Mag]
    $w.fTbl.txt insert end "$hdr\n[string repeat - 78]\n"

    foreach row $data {
        set eid [Get1DRowVal $row EID]
        set vx  [Fmt1DVal    [Get1DRowVal $row X]]
        set vy  [Fmt1DVal    [Get1DRowVal $row Y]]
        set vz  [Fmt1DVal    [Get1DRowVal $row Z]]
        set vm  [Fmt1DVal    [Get1DRowVal $row Mag]]
        $w.fTbl.txt insert end \
            "[format {%-10s  %16s  %16s  %16s  %16s} $eid $vx $vy $vz $vm]\n"
    }
    $w.fTbl.txt configure -state disabled

    if {$loadsOutputFile ne ""} {
        set csvInfo "CSV: [file tail $loadsOutputFile]"
    } else {
        set csvInfo "CSV kaydedilmedi"
    }
    label $w.lCount \
        -text "[llength $data] element  |  $csvInfo" \
        -font {Helvetica 8} -fg #444444
    pack $w.lCount -pady {0 2}

    button $w.bClose -text "Kapat" -width 10 -command [list destroy $w]
    pack $w.bClose -pady {0 6}

    CenterWindow $w
}

# -----------------------------------------------------------------------------
# ExportLoadsToCSV — Çıkarılan yükleri CSV dosyasına yazar
# -----------------------------------------------------------------------------
proc NastranResultsLoader::ExportLoadsToCSV {subcaseID} {
    variable extractedLoads
    variable loadsOutputFile
    variable elem1DTypeVar
    variable mainWin

    if {[llength $extractedLoads] == 0} {
        SetStatus "CSV için veri yok."
        return
    }

    set rc [catch {
        set fh [open $loadsOutputFile w]
        puts $fh "# 1D Element Loads — HyperMesh 2019.1 Aerospace"
        puts $fh "# Subcase: $subcaseID"
        puts $fh "# Result Type: $elem1DTypeVar"
        puts $fh "# System: Elemental | Avg Method: None | Corners: False"
        puts $fh "ElemID,X,Y,Z,Mag"
        foreach row $extractedLoads {
            puts $fh "[Get1DRowVal $row EID],[Get1DRowVal $row X],[Get1DRowVal $row Y],[Get1DRowVal $row Z],[Get1DRowVal $row Mag]"
        }
        close $fh
        SetStatus "CSV kaydedildi: [file tail $loadsOutputFile] ([llength $extractedLoads] element)"
    } err]

    if {$rc != 0} {
        tk_messageBox -icon error -title "CSV Kayıt Hatası" \
            -message "Dosya yazılamadı:\n$err" \
            -parent $mainWin
        SetStatus "HATA: CSV kaydedilemedi."
    }
}

# -----------------------------------------------------------------------------
# Yardımcı prosedürler — 1D yük çıkarımı
# -----------------------------------------------------------------------------
proc NastranResultsLoader::Get1DRowVal {row key} {
    foreach {k v} $row {
        if {$k eq $key} { return $v }
    }
    return "N/A"
}

proc NastranResultsLoader::Fmt1DVal {val} {
    if {$val eq "N/A"} { return "N/A" }
    if {[catch {set s [format "%.6e" $val]}]} { return $val }
    return $s
}
