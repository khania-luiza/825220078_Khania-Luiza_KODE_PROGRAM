<%@ Import Namespace="iTextSharp.text" %>
<%@ Import Namespace="iTextSharp.text.pdf" %>
<%@ Import Namespace="System.Data.SqlClient" %>
<%@ Import Namespace="System.Data" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<%@ Import Namespace="System.Linq" %>
<%@ Import Namespace="System.IO.Compression" %>
<%@ Import Namespace="iTextSharp.text" %>
<%@ Import Namespace="System.Web.Script.Serialization" %>
<%@ Import Namespace="System.Data.OleDb" %>

<!-- #INCLUDE file ="../../con_ascx2022/conlintar2022.ascx" -->
<!-- #INCLUDE file ="../../con_ascx2022/conakd.ascx" -->
<!-- #INCLUDE file ="../../con_ascx2022/consadar.ascx" -->
<!-- #INCLUDE file ="../../con_ascx2022/condecdummy.ascx" -->
<!-- #INCLUDE file ="../../con_ascx2022/conadmawa.ascx" -->

<script runat="server">
    ' ------------------------------------------------------------
    ' Konstanta nama tabel database. Dengan mendefinisikan nama tabel
    ' di satu tempat, Anda dapat dengan mudah mengganti nama tabel
    ' tanpa harus mencari dan mengubah di banyak lokasi dalam kode.
    Private Const TABEL_JAWABAN As String = "tbl_rekom_jawaban"
    Private Const TABEL_REKOMENDASI As String = "tbl_rekom_rekomendasi"
    ' Disable UnobtrusiveValidationMode in Page_Init
    Protected Overrides Sub OnInit(e As EventArgs)
        Me.Page.UnobtrusiveValidationMode = System.Web.UI.UnobtrusiveValidationMode.None
        MyBase.OnInit(e)
    End Sub
    
    ' Property untuk menyimpan pertanyaan dari database
    Protected ReadOnly Property Questions As List(Of String)
        Get
            Return GetQuestionsFromDatabase()
        End Get
    End Property
    
    ' Method untuk mengambil pertanyaan dari database
    ' Fungsi ini mengambil daftar pertanyaan dari database (tbl_rekom_pertanyaan).
    ' Pertanyaan diurutkan berdasarkan id_pertanyaan dan dikembalikan sebagai List(Of String).
    ' Hasilnya digunakan untuk menampilkan kuisioner kepada mahasiswa di antarmuka Web Forms.
    Private Function GetQuestionsFromDatabase() As List(Of String)
        Dim daftarPertanyaan As New List(Of String)()
        
        Try
            ' Menggunakan koneksi dari file include
            Dim conn As New OleDbConnection(connstringlintar)
            
            ' Query SQL untuk mengambil pertanyaan dari database. Menggunakan
            ' variabel sqlPertanyaan agar nama variabel lebih jelas dan mudah dipahami.
            Dim sqlPertanyaan As String = ""
            
            ' Cek apakah menggunakan SQL Server atau database lain
            If connstringlintar.ToLower().Contains("sql") Then
                ' Untuk SQL Server
                sqlPertanyaan = "SELECT pertanyaan FROM admawa.dbo.tbl_rekom_pertanyaan ORDER BY id_pertanyaan"
            Else
                ' Untuk database lain (Access, dll)
                sqlPertanyaan = "SELECT pertanyaan FROM tbl_rekom_pertanyaan ORDER BY id_pertanyaan"
            End If
            
            ' Debug: Log query yang akan dieksekusi
            System.Diagnostics.Debug.WriteLine("Query pertanyaan: " & sqlPertanyaan)
            System.Diagnostics.Debug.WriteLine("Connection string: " & connstringlintar)
            System.Diagnostics.Debug.WriteLine("Database provider: " & conn.Provider)
            
            Using cmd As New OleDbCommand(sqlPertanyaan, conn)
                conn.Open()
                
                ' Debug: Log koneksi berhasil
                System.Diagnostics.Debug.WriteLine("Koneksi database berhasil dibuka")
                
                ' Membaca data dari database
                Using reader As OleDbDataReader = cmd.ExecuteReader()
                    While reader.Read()
                        ' Menambahkan pertanyaan ke dalam list
                        Dim pertanyaan As String = reader("pertanyaan").ToString()
                        daftarPertanyaan.Add(pertanyaan)
                        
                        ' Debug: Log setiap pertanyaan yang dibaca
                        System.Diagnostics.Debug.WriteLine("Pertanyaan " & daftarPertanyaan.Count & ": " & pertanyaan)
                    End While
                End Using
                
                conn.Close()
                System.Diagnostics.Debug.WriteLine("Koneksi database ditutup")
            End Using
            
            ' Debug: Log jumlah pertanyaan yang diambil
            System.Diagnostics.Debug.WriteLine("Jumlah pertanyaan yang diambil dari database: " & daftarPertanyaan.Count)
            
        Catch ex As Exception
            ' Jika terjadi error, tampilkan pesan error dan throw exception
            System.Diagnostics.Debug.WriteLine("Error mengambil pertanyaan dari database: " & ex.Message)
            System.Diagnostics.Debug.WriteLine("Stack trace: " & ex.StackTrace)
            Throw New Exception("Gagal mengambil pertanyaan dari database: " & ex.Message)
        End Try
        
        Return daftarPertanyaan
    End Function


    ' Kelas data UKM untuk menyimpan nama dan skor
    Private Class DataUkm
        Public Property Nama As String
        Public Property Skor As Integer()
        
        Public Sub New(nama As String, skor As Integer())
            Me.Nama = nama
            Me.Skor = skor
        End Sub
    End Class
    
    ' Data UKM dengan skor untuk setiap pertanyaan (1-20)
    ' Bobot: 1=tidak penting, 2=agak penting, 3=penting, 4=sangat penting, 5=kritis
    ' Berdasarkan pemetaan pertanyaan:
    ' Q1=Musik/Bernyanyi, Q2=Teater/Akting, Q3=Olahraga Kompetitif, Q4=Bela Diri, Q5=Kegiatan Alam
    ' Q6=Fotografi/Visual, Q7=Diskusi/Berbagi Ide, Q8=Komunitas Agama, Q9=Budaya Jepang, Q10=Bahasa Inggris
    ' Q11=Organisasi/Kepemimpinan, Q12=Desain/Tata Rias, Q13=Seni Sulap, Q14=Media/Radio, Q15=Bela Diri Tradisional
    ' Q16=Pelayanan Rohani/Sosial, Q17=Tantangan Fisik, Q18=Event/Perencanaan, Q19=Kerja Kelompok, Q20=Komunitas Hobi
    ' Fungsi ini memuat data UKM dalam bentuk Dictionary.
    ' Setiap UKM memiliki array Integer berukuran 20 yang mewakili bobot/tingkat relevansi
    ' terhadap setiap pertanyaan (1–20) untuk algoritma weighted scoring.
    Private Function GetUkmData() As Dictionary(Of String, Integer())
        Return New Dictionary(Of String, Integer()) From {
            {"Band Tarumanagara (BAR)", New Integer() {5,2,1,1,1,2,2,1,1,2,3,3,2,4,1,2,2,5,4,4}},
            {"Seni Teater Tarumanagara", New Integer() {3,5,1,1,1,3,4,1,2,2,4,5,3,3,1,2,2,5,5,4}},
            {"FUT (Ukhuwah Muslim)", New Integer() {1,1,1,1,1,1,3,5,1,1,2,1,1,2,1,5,1,3,4,5}},
            {"POUT (Kerohanian Kristen)", New Integer() {1,1,1,1,1,1,3,5,1,1,2,1,1,2,1,5,1,3,4,5}},
            {"Liga Tenis Meja (LTMU)", New Integer() {1,1,5,2,2,1,2,1,1,1,2,1,1,1,1,1,5,2,3,3}},
            {"Liga Voli (LIVOSTA)", New Integer() {1,1,5,2,2,1,2,1,1,1,2,1,1,1,1,1,5,3,4,3}},
            {"Liga Futsal", New Integer() {1,1,5,2,2,1,2,1,1,1,2,1,1,1,1,1,5,2,4,3}},
            {"Liga Basket (LIBAMA)", New Integer() {1,1,5,2,2,1,2,1,1,1,2,1,1,1,1,1,5,2,4,3}},
            {"FESTA (Sulap)", New Integer() {2,4,1,1,1,3,2,1,2,2,2,4,5,3,1,2,2,4,3,4}},
            {"Paduan Suara (PSUT)", New Integer() {5,2,1,1,1,2,2,1,1,2,3,2,1,3,1,2,2,4,4,4}},
            {"Fotografi (PFT)", New Integer() {1,2,1,1,2,5,2,1,1,2,2,4,1,2,1,1,1,3,3,4}},
            {"Radio UNTAR", New Integer() {3,2,1,1,1,3,5,1,1,4,3,3,2,5,1,2,1,5,3,4}},
            {"Nihon Bu (Jepang)", New Integer() {1,2,1,1,2,3,2,1,5,2,2,3,2,2,2,1,2,3,3,4}},
            {"English Club (TEC)", New Integer() {1,1,1,1,1,2,3,1,1,5,3,2,1,3,1,2,1,3,3,4}},
            {"WMKT", New Integer() {2,2,1,1,1,2,5,1,1,2,5,3,1,3,1,4,2,4,5,4}},
            {"MAHUPA", New Integer() {1,1,4,2,5,2,2,1,1,1,3,2,1,1,2,2,5,3,4,3}},
            {"MARSIPALA", New Integer() {1,1,4,2,5,2,2,1,1,1,3,2,1,1,2,2,5,3,4,3}},
            {"MEGA", New Integer() {1,1,4,2,5,2,2,1,1,1,3,2,1,1,2,2,5,3,4,3}},
            {"KMK Adhyatmaka (Katolik)", New Integer() {1,1,1,1,1,1,3,5,1,1,2,1,1,2,1,5,1,3,4,5}},
            {"KBMK (Konghucu)", New Integer() {1,1,1,1,1,1,3,5,1,1,2,1,1,2,1,5,1,3,4,5}},
            {"LBUT (Bulutangkis)", New Integer() {1,1,5,2,2,1,2,1,1,1,2,1,1,1,1,1,5,2,3,3}},
            {"Citra Pesona (CP)", New Integer() {2,4,2,1,2,4,3,1,1,2,4,5,2,3,1,3,2,5,5,4}},
            {"KMB Dharmayana (Buddha)", New Integer() {1,1,1,1,1,1,3,5,1,1,2,1,1,2,1,5,1,3,4,5}},
            {"Taekwondo", New Integer() {1,1,4,5,2,1,2,1,1,1,2,1,1,1,5,2,5,2,3,3}},
            {"Wushu", New Integer() {1,1,4,5,2,1,2,1,1,1,2,1,1,1,5,2,5,2,3,3}}
        }
    End Function
    
    ' Kelas untuk menyimpan hasil rekomendasi UKM
    Public Class RekomendasiUkm
        Public Property Nama As String
        Public Property Skor As Integer
        Public Property Deskripsi As String
    End Class
    
    ' Deskripsi UKM
    ' Fungsi ini mengembalikan deskripsi singkat masing-masing UKM.
    ' Deskripsi ditampilkan kepada pengguna bersama dengan nama UKM pada halaman hasil rekomendasi.
    Private Function GetUkmDescriptions() As Dictionary(Of String, String)
        Dim __tmpDict1 As New Dictionary(Of String, String)
            __tmpDict1.Add("Band Tarumanagara (BAR)", "Mengembangkan bakat musik dan bernyanyi dalam grup band. Cocok untuk yang suka bermain alat musik atau bernyanyi.")
            __tmpDict1.Add("Seni Teater Tarumanagara", "Mengembangkan bakat akting dan seni peran. Cocok untuk yang tertarik berakting atau tampil di panggung teater.")
            __tmpDict1.Add("FUT (Ukhuwah Muslim)", "Komunitas keagamaan Islam yang fokus pada pelayanan rohani dan sosial.")
            __tmpDict1.Add("POUT (Kerohanian Kristen)", "Komunitas keagamaan Kristen yang fokus pada pelayanan rohani dan sosial.")
            __tmpDict1.Add("Liga Tenis Meja (LTMU)", "UKM olahraga tenis meja untuk mengembangkan bakat olahraga kompetitif.")
            __tmpDict1.Add("Liga Voli (LIVOSTA)", "UKM olahraga voli untuk mengembangkan bakat olahraga kompetitif.")
            __tmpDict1.Add("Liga Futsal", "UKM olahraga futsal untuk mengembangkan bakat olahraga kompetitif.")
            __tmpDict1.Add("Liga Basket (LIBAMA)", "UKM olahraga basket untuk mengembangkan bakat olahraga kompetitif.")
            __tmpDict1.Add("FESTA (Sulap)", "UKM sulap dan trik-trik mengejutkan. Cocok untuk yang tertarik dengan dunia sulap.")
            __tmpDict1.Add("Paduan Suara (PSUT)", "UKM paduan suara untuk mengembangkan bakat musik dan bernyanyi.")
            __tmpDict1.Add("Fotografi (PFT)", "UKM fotografi dan konten visual. Cocok untuk yang menikmati kegiatan fotografi.")
            __tmpDict1.Add("Radio UNTAR", "UKM radio dan media. Cocok untuk yang suka tampil di media seperti radio atau podcast.")
            __tmpDict1.Add("Nihon Bu (Jepang)", "UKM budaya Jepang. Cocok untuk yang tertarik dengan budaya Jepang.")
            __tmpDict1.Add("English Club (TEC)", "UKM bahasa Inggris. Cocok untuk yang ingin memperdalam kemampuan berbahasa Inggris.")
            __tmpDict1.Add("WMKT", "UKM yang fokus pada diskusi isu sosial dan kampus.")
            __tmpDict1.Add("MAHUPA", "UKM kegiatan alam dan petualangan. Cocok untuk yang menyukai kegiatan alam.")
            __tmpDict1.Add("MARSIPALA", "UKM kegiatan alam dan petualangan. Cocok untuk yang menyukai kegiatan alam.")
            __tmpDict1.Add("MEGA", "UKM kegiatan alam dan petualangan. Cocok untuk yang menyukai kegiatan alam.")
            __tmpDict1.Add("KMK Adhyatmaka (Katolik)", "Komunitas keagamaan Katolik yang fokus pada pelayanan rohani dan sosial.")
            __tmpDict1.Add("KBMK (Konghucu)", "Komunitas keagamaan Konghucu yang fokus pada pelayanan rohani dan sosial.")
            __tmpDict1.Add("LBUT (Bulutangkis)", "UKM olahraga bulutangkis untuk mengembangkan bakat olahraga kompetitif.")
            __tmpDict1.Add("Citra Pesona (CP)", "UKM yang fokus pada pelayanan rohani, sosial, dan event kreatif. Cocok untuk yang suka membantu orang lain dan event kreatif.")
            __tmpDict1.Add("KMB Dharmayana (Buddha)", "Komunitas keagamaan Buddha yang fokus pada pelayanan rohani dan sosial.")
            __tmpDict1.Add("Taekwondo", "UKM bela diri Taekwondo. Cocok untuk yang ingin belajar dan mengembangkan kemampuan bela diri.")
            __tmpDict1.Add("Wushu", "UKM bela diri tradisional Wushu. Cocok untuk yang ingin mengembangkan potensi dalam seni bela diri tradisional.")
        Return __tmpDict1
    End Function
    
    ' Shared method untuk mendapatkan aturan pengecualian UKM
    ' Fungsi ini mendefinisikan aturan pengecualian untuk setiap pertanyaan.
    ' Jika mahasiswa menjawab > 3 (tidak setuju/sangat tidak setuju) pada pertanyaan tertentu,
    ' maka UKM yang tercantum pada daftar pengecualian untuk pertanyaan tersebut tidak akan direkomendasikan.
    Private Function GetExclusionRules() As Dictionary(Of Integer, List(Of String))
        Dim pengecualianUkm As New Dictionary(Of Integer, List(Of String))()
        pengecualianUkm.Add(1, New List(Of String) From {"Band Tarumanagara (BAR)", "Paduan Suara (PSUT)"})
        pengecualianUkm.Add(2, New List(Of String) From {"Seni Teater Tarumanagara"})
        pengecualianUkm.Add(3, New List(Of String) From {"Liga Basket (LIBAMA)", "Liga Futsal", "Liga Voli (LIVOSTA)", "LBUT (Bulutangkis)", "Liga Tenis Meja (LTMU)"})
        ' Pertanyaan 4: Bela diri umum (Taekwondo, Wushu, Jujitsu). Jika jawaban > 3, hindari semua UKM yang terkait.
        pengecualianUkm.Add(4, New List(Of String) From {"Taekwondo", "Wushu", "Jujitsu Tarumanagara"})
        pengecualianUkm.Add(5, New List(Of String) From {"MAHUPA", "MARSIPALA", "MEGA"})
        pengecualianUkm.Add(6, New List(Of String) From {"Fotografi (PFT)", "Citra Pesona (CP)"})
        pengecualianUkm.Add(7, New List(Of String) From {"WMKT"})
        pengecualianUkm.Add(8, New List(Of String) From {"POUT (Kerohanian Kristen)", "KMK Adhyatmaka (Katolik)", "FUT (Ukhuwah Muslim)", "KBMK (Konghucu)", "KMB Dharmayana (Buddha)"})
        pengecualianUkm.Add(9, New List(Of String) From {"Nihon Bu (Jepang)"})
        pengecualianUkm.Add(10, New List(Of String) From {"English Club (TEC)"})
        pengecualianUkm.Add(11, New List(Of String) From {"WMKT", "Citra Pesona (CP)"})
        pengecualianUkm.Add(12, New List(Of String) From {"Citra Pesona (CP)", "Seni Teater Tarumanagara"})
        pengecualianUkm.Add(13, New List(Of String) From {"FESTA (Sulap)"})
        pengecualianUkm.Add(14, New List(Of String) From {"Radio UNTAR"})
        ' Pertanyaan 15: Bela diri tradisional seperti Wushu/Jujitsu. Jika jawaban > 3, hindari UKM terkait.
        pengecualianUkm.Add(15, New List(Of String) From {"Wushu", "Jujitsu Tarumanagara"})
        pengecualianUkm.Add(16, New List(Of String) From {"POUT (Kerohanian Kristen)", "KMK Adhyatmaka (Katolik)", "KBMK (Konghucu)", "KMB Dharmayana (Buddha)", "FUT (Ukhuwah Muslim)"})
        pengecualianUkm.Add(17, New List(Of String) From {"MAHUPA", "MEGA", "MARSIPALA", "Taekwondo", "Wushu", "Liga Basket (LIBAMA)", "Liga Futsal", "Liga Voli (LIVOSTA)", "LBUT (Bulutangkis)", "Liga Tenis Meja (LTMU)"})
        pengecualianUkm.Add(18, New List(Of String) From {"Citra Pesona (CP)", "WMKT"})
        pengecualianUkm.Add(20, New List(Of String)()) ' Untuk pertanyaan 20, semua UKM bisa dikecualikan jika nilai = 5
        Return pengecualianUkm
    End Function

    '===========================================
    '  FUNGSI MAPPING PERTANYAAN KE SETIAP UKM
    '===========================================
    ' Fungsi ini mendefinisikan secara eksplisit pertanyaan-pertanyaan mana yang relevan untuk setiap UKM.
    ' Setiap UKM dipetakan ke daftar ID pertanyaan. Pertanyaan-pertanyaan ini dianggap sebagai indikator
    ' ketertarikan utama untuk UKM tersebut. Skor UKM dihitung dengan menjumlahkan nilai jawaban mahasiswa
    ' pada pertanyaan-pertanyaan tersebut (1–5). Semakin tinggi total skor, semakin cocok UKM untuk mahasiswa.
    ' Fungsi ini memetakan setiap UKM dengan daftar ID pertanyaan yang relevan.
    ' Digunakan oleh algoritma sederhana berbasis penjumlahan skor untuk menghitung total poin per UKM.
    Private Function GetUkmQuestionMapping() As Dictionary(Of String, List(Of Integer))
        ' Mapping UKM ke pertanyaan yang relevan (hanya pertanyaan utama tanpa pertanyaan umum seperti 18–20).
        Return New Dictionary(Of String, List(Of Integer))(StringComparer.OrdinalIgnoreCase) From {
            {"Band Tarumanagara (BAR)", New List(Of Integer) From {1}},
            {"Paduan Suara (PSUT)", New List(Of Integer) From {1}},
            {"Seni Teater Tarumanagara", New List(Of Integer) From {2, 12, 18}},
            {"Citra Pesona (CP)", New List(Of Integer) From {18}},
            {"Radio UNTAR", New List(Of Integer) From {14}},
            {"Fotografi (PFT)", New List(Of Integer) From {6}},
            {"MAHUPA", New List(Of Integer) From {5, 17}},
            {"MARSIPALA", New List(Of Integer) From {5, 17}},
            {"MEGA", New List(Of Integer) From {5, 17}},
            {"Nihon Bu (Jepang)", New List(Of Integer) From {9}},
            {"Taekwondo", New List(Of Integer) From {4, 15}},
            {"Wushu", New List(Of Integer) From {4, 15}},
            {"Jujitsu Tarumanagara", New List(Of Integer) From {4, 15}},
            {"Liga Basket (LIBAMA)", New List(Of Integer) From {3, 17}},
            {"Liga Futsal", New List(Of Integer) From {3, 17}},
            {"Liga Voli (LIVOSTA)", New List(Of Integer) From {3, 17}},
            {"LBUT (Bulutangkis)", New List(Of Integer) From {3, 17}},
            {"Liga Tenis Meja (LTMU)", New List(Of Integer) From {3, 17}},
            {"FESTA (Sulap)", New List(Of Integer) From {13}},
            {"English Club (TEC)", New List(Of Integer) From {10}},
            {"WMKT", New List(Of Integer) From {7, 11}},
            {"FUT (Ukhuwah Muslim)", New List(Of Integer) From {8, 16}},
            {"POUT (Kerohanian Kristen)", New List(Of Integer) From {8, 16}},
            {"KMK Adhyatmaka (Katolik)", New List(Of Integer) From {8, 16}},
            {"KBMK (Konghucu)", New List(Of Integer) From {8, 16}},
            {"KMB Dharmayana (Buddha)", New List(Of Integer) From {8, 16}}
        }
    End Function

    ' Fungsi untuk menghitung rekomendasi UKM berdasarkan mapping pertanyaan.
    ' Setiap UKM akan mendapatkan skor yang merupakan jumlah dari nilai jawaban mahasiswa
    ' pada pertanyaan yang relevan (sesuai mapping). Kembalikan daftar rekomendasi urut
    ' menurun berdasarkan skor. Jika tidak ada skor > 0, kembalikan daftar kosong.
    ' Fungsi ini menghasilkan rekomendasi UKM berdasarkan mapping pertanyaan.
    ' Skor dihitung dengan menjumlahkan poin (6 - jawaban) untuk setiap pertanyaan relevan.
    ' Aturan pengecualian diterapkan untuk menghapus UKM jika jawaban mahasiswa menunjukkan ketidaksukaan.
    ' Jika ada lebih dari 5 UKM dengan skor sama, semua UKM tersebut diikutkan dalam hasil.
    Private Function GenerateSimpleRecommendations(ByVal jawabanMahasiswa As Dictionary(Of Integer, Integer)) As List(Of RekomendasiUkm)
        Dim rekomendasiList As New List(Of RekomendasiUkm)()
        If jawabanMahasiswa Is Nothing OrElse jawabanMahasiswa.Count = 0 Then
            Return rekomendasiList
        End If

        ' Buat salinan jawaban yang hanya berisi pertanyaan reguler (1–20) untuk perhitungan skor.
        ' Pertanyaan khusus (21: jenis kelamin, 22: penyakit) tidak memengaruhi rekomendasi UKM.
        Dim filteredJawaban As New Dictionary(Of Integer, Integer)()
        For Each kvp In jawabanMahasiswa
            If kvp.Key <= 20 Then
                filteredJawaban(kvp.Key) = kvp.Value
            End If
        Next

        Dim pemetaanPertanyaanUkm As Dictionary(Of String, List(Of Integer)) = GetUkmQuestionMapping()
        Dim deskripsiUkm = GetUkmDescriptions()

        ' Ambil aturan pengecualian untuk menyingkirkan UKM yang tidak disukai berdasarkan jawaban
        Dim pengecualianUkm As Dictionary(Of Integer, List(Of String)) = GetExclusionRules()

        For Each pasangan In pemetaanPertanyaanUkm
            Dim namaUkm As String = pasangan.Key
            Dim daftarIdPertanyaan As List(Of Integer) = pasangan.Value

            ' Periksa apakah UKM ini harus dikecualikan. Gunakan jawaban yang difilter.
            Dim harusDilewati As Boolean = False
            For Each pasanganJawaban In filteredJawaban
                Dim pid As Integer = pasanganJawaban.Key
                Dim ansVal As Integer = pasanganJawaban.Value
                If ansVal > 3 AndAlso pengecualianUkm IsNot Nothing AndAlso pengecualianUkm.ContainsKey(pid) Then
                    Dim excludedList As List(Of String) = pengecualianUkm(pid)
                    If excludedList IsNot Nothing AndAlso excludedList.Contains(namaUkm) Then
                        harusDilewati = True
                        Exit For
                    End If
                End If
            Next
            If harusDilewati Then
                Continue For
            End If

            Dim totalScore As Integer = 0
            For Each idPertanyaan As Integer In daftarIdPertanyaan
                If filteredJawaban.ContainsKey(idPertanyaan) Then
                    ' Konversi skala terbalik (1 = sangat setuju, 5 = sangat tidak setuju) ke poin (5 = sangat setuju, 1 = sangat tidak setuju)
                    Dim ansVal As Integer = filteredJawaban(idPertanyaan)
                    Dim poin As Integer = 6 - ansVal
                    totalScore += poin
                End If
            Next

            ' Hitung skor maksimum yang mungkin untuk UKM ini (jumlah pertanyaan relevan × 5 poin maksimum)
            Dim maxScore As Integer = daftarIdPertanyaan.Count * 5

            ' Konversi skor total ke persentase kecocokan (0-100%)
            Dim percentage As Integer = 0
            If maxScore > 0 Then
                Dim perc As Double = (totalScore / maxScore) * 100
                percentage = CInt(Math.Round(perc))
            End If

            ' Hanya tambahkan UKM dengan persentase > 0
            If percentage > 0 Then
                Dim desc As String = If(deskripsiUkm.ContainsKey(namaUkm), deskripsiUkm(namaUkm), "")
                rekomendasiList.Add(New RekomendasiUkm() With {
                    .Nama = namaUkm,
                    .Skor = percentage,
                    .Deskripsi = desc
                })
            End If
        Next
        ' Urutkan menurun berdasarkan skor
        Dim sortedList = rekomendasiList.OrderByDescending(Function(r) r.Skor).ToList()

        ' Jika ada lebih dari 5 UKM dan UKM ke-6 memiliki skor sama dengan UKM ke-5,
        ' sertakan semua UKM yang memiliki skor minimal sama dengan skor UKM ke-5.
        ' Ini menghindari situasi di mana UKM dengan skor sama dipotong secara arbitrer.
        If sortedList.Count > 5 Then
            Dim thresholdScore As Integer = sortedList(4).Skor
            sortedList = sortedList.Where(Function(r) r.Skor >= thresholdScore).ToList()
        End If

        Return sortedList
    End Function
    
    ' Pemetaan eksplisit: Pertanyaan -> UKM yang paling relevan (berdasarkan tabel user)
    ' Pemetaan eksplisit pertanyaan ke daftar UKM relevan.
    ' Digunakan oleh algoritma weighted scoring untuk memberi boost pada UKM yang sesuai dengan pertanyaan tertentu.
    Private Function GetQuestionToUkmMap() As Dictionary(Of Integer, List(Of String))
        Dim map As New Dictionary(Of Integer, List(Of String))()
        map.Add(1, New List(Of String) From {"Band Tarumanagara (BAR)", "Paduan Suara (PSUT)"})
        map.Add(2, New List(Of String) From {"Seni Teater Tarumanagara"})
        map.Add(3, New List(Of String) From {"Liga Basket (LIBAMA)", "Liga Futsal", "Liga Voli (LIVOSTA)"})
        map.Add(4, New List(Of String) From {"Taekwondo", "Wushu"}) ' Jujitsu tidak tersedia di data, di-skip
        map.Add(5, New List(Of String) From {"MAHUPA", "MARSIPALA", "MEGA"})
        map.Add(6, New List(Of String) From {"Fotografi (PFT)"})
        map.Add(7, New List(Of String) From {"WMKT"})
        map.Add(8, New List(Of String) From {"FUT (Ukhuwah Muslim)", "POUT (Kerohanian Kristen)", "KMK Adhyatmaka (Katolik)", "KBMK (Konghucu)", "KMB Dharmayana (Buddha)"})
        map.Add(9, New List(Of String) From {"Nihon Bu (Jepang)"})
        map.Add(10, New List(Of String) From {"English Club (TEC)"})
        ' 11: Organisasi/Kepemimpinan (BEM/Himpunan) tidak termasuk UKM minat bakat di data ini
        map.Add(12, New List(Of String) From {"Seni Teater Tarumanagara", "Citra Pesona (CP)"})
        map.Add(13, New List(Of String) From {"Radio UNTAR"})
        map.Add(14, New List(Of String) From {"FESTA (Sulap)", "Nihon Bu (Jepang)"})
        map.Add(15, New List(Of String) From {"Liga Basket (LIBAMA)", "Liga Futsal", "Liga Voli (LIVOSTA)", "LBUT (Bulutangkis)", "Liga Tenis Meja (LTMU)"})
        map.Add(16, New List(Of String) From {"Taekwondo", "Wushu", "MAHUPA", "MARSIPALA", "MEGA"})
        map.Add(17, New List(Of String) From {"Citra Pesona (CP)"})
        ' 18: Kegiatan kelompok (BEM/UKM umum) – tidak spesifik, di-skip
        map.Add(19, New List(Of String) From {"Citra Pesona (CP)"}) ' Event kampus -> EO internal/CP
        ' 20: Komunitas minat sama – akan ditangani di logika umum (gabungan), tidak spesifik ke satu UKM
        Return map
    End Function

    ' Pemetaan kategori per pertanyaan (untuk contextual weighting)
    ' Pemetaan kategori per pertanyaan.
    ' Tiap pertanyaan dikaitkan dengan kategori seperti musik, teater, olahraga_tim, dan seterusnya.
    ' Kategori ini digunakan dalam algoritma weighted scoring untuk memberikan faktor boost berdasarkan kesamaan kategori.
    Private Function GetQuestionCategories() As Dictionary(Of Integer, String)
        Dim qc As New Dictionary(Of Integer, String)()
        qc.Add(1, "musik")
        qc.Add(2, "teater")
        qc.Add(3, "olahraga_tim")
        qc.Add(4, "bela_diri")
        qc.Add(5, "alam_outdoor")
        qc.Add(6, "fotografi")
        qc.Add(7, "kewirausahaan")
        qc.Add(8, "kerohanian")
        qc.Add(9, "budaya")
        qc.Add(10, "bahasa")
        qc.Add(11, "organisasi")
        qc.Add(12, "seni_event")
        qc.Add(13, "media")
        qc.Add(14, "hobi_komunitas")
        qc.Add(15, "olahraga_individu")
        qc.Add(16, "petualangan")
        qc.Add(17, "kerelawanan")
        qc.Add(18, "organisasi")
        qc.Add(19, "event")
        qc.Add(20, "komunitas")
        Return qc
    End Function

    ' Pemetaan kategori per UKM (bisa multi-kategori)
    ' Pemetaan kategori per UKM.
    ' Setiap UKM dapat memiliki beberapa kategori (misalnya "olahraga" dan "bela_diri").
    ' Digunakan dalam algoritma weighted scoring untuk meningkatkan skor jika kategori UKM cocok dengan kategori pertanyaan.
    Private Function GetUkmCategories() As Dictionary(Of String, List(Of String))
        Dim uc As New Dictionary(Of String, List(Of String))()
        uc.Add("Band Tarumanagara (BAR)", New List(Of String) From {"musik"})
        uc.Add("Paduan Suara (PSUT)", New List(Of String) From {"musik"})
        uc.Add("Seni Teater Tarumanagara", New List(Of String) From {"teater", "seni_event"})
        uc.Add("Liga Basket (LIBAMA)", New List(Of String) From {"olahraga", "olahraga_tim"})
        uc.Add("Liga Futsal", New List(Of String) From {"olahraga", "olahraga_tim"})
        uc.Add("Liga Voli (LIVOSTA)", New List(Of String) From {"olahraga", "olahraga_tim"})
        uc.Add("LBUT (Bulutangkis)", New List(Of String) From {"olahraga", "olahraga_individu"})
        uc.Add("Liga Tenis Meja (LTMU)", New List(Of String) From {"olahraga", "olahraga_individu"})
        uc.Add("Taekwondo", New List(Of String) From {"olahraga", "bela_diri"})
        uc.Add("Wushu", New List(Of String) From {"olahraga", "bela_diri"})
        uc.Add("MAHUPA", New List(Of String) From {"alam_outdoor", "petualangan"})
        uc.Add("MARSIPALA", New List(Of String) From {"alam_outdoor", "petualangan"})
        uc.Add("MEGA", New List(Of String) From {"alam_outdoor", "petualangan"})
        uc.Add("Fotografi (PFT)", New List(Of String) From {"fotografi", "media"})
        uc.Add("WMKT", New List(Of String) From {"kewirausahaan"})
        uc.Add("POUT (Kerohanian Kristen)", New List(Of String) From {"kerohanian"})
        uc.Add("KMK Adhyatmaka (Katolik)", New List(Of String) From {"kerohanian"})
        uc.Add("FUT (Ukhuwah Muslim)", New List(Of String) From {"kerohanian"})
        uc.Add("KBMK (Konghucu)", New List(Of String) From {"kerohanian"})
        uc.Add("KMB Dharmayana (Buddha)", New List(Of String) From {"kerohanian"})
        uc.Add("Nihon Bu (Jepang)", New List(Of String) From {"budaya", "hobi_komunitas"})
        uc.Add("English Club (TEC)", New List(Of String) From {"bahasa", "hobi_komunitas"})
        uc.Add("Citra Pesona (CP)", New List(Of String) From {"event", "kerelawanan", "media"})
        uc.Add("Radio UNTAR", New List(Of String) From {"media"})
        uc.Add("FESTA (Sulap)", New List(Of String) From {"hobi_komunitas"})
        Return uc
    End Function
    
    ' Method untuk mendapatkan rekomendasi UKM berdasarkan jawaban
    ' ALGORITMA WEIGHTED SCORING (Versi 6.0 - dengan pemetaan pertanyaan->UKM):
    ' 1. Hitung skor untuk setiap UKM berdasarkan rumus: (6 - jawaban) * bobot
    '    - Jawaban 1 (Sangat Setuju) = 5 poin * bobot
    '    - Jawaban 2 (Setuju) = 4 poin * bobot
    '    - Jawaban 3 (Netral) = 3 poin * bobot
    '    - Jawaban 4 (Tidak Setuju) = 2 poin * bobot
    '    - Jawaban 5 (Sangat Tidak Setuju) = 1 poin * bobot
    ' 2. Hitung persentase kecocokan: (skor aktual / skor maksimal) * 100
    ' 3. Tambahkan faktor boost jika UKM termasuk dalam daftar relevan untuk pertanyaan tsb (berdasarkan tabel)
    ' 4. Urutkan UKM berdasarkan persentase tertinggi
    ' 5. Kembalikan 5 UKM teratas dengan persentase >= 30%
    '
    ' Skala Jawaban:
    ' 1 = Sangat Setuju (5 poin)
    ' 2 = Setuju (4 poin)
    ' 3 = Netral/Ragu-Ragu (3 poin)
    ' 4 = Tidak Setuju (2 poin)
    ' 5 = Sangat Tidak Setuju (1 poin)
    ' Algoritma weighted scoring (versi lanjutan).
    ' Skor UKM dihitung untuk setiap pertanyaan menggunakan rumus: (6 - jawaban) × bobot.
    ' Setelah itu persentase kecocokan dihitung dengan membandingkan skor aktual dengan skor maksimal.
    ' Faktor boost diberikan jika UKM relevan langsung dengan pertanyaan atau memiliki kategori yang cocok.
    ' Hasil diurutkan dan UKM dengan persentase di atas ambang tertentu dikembalikan sebagai rekomendasi.
    Private Function DapatkanRekomendasiUkm(jawaban As Dictionary(Of Integer, Integer)) As List(Of RekomendasiUkm)
        Dim daftarRekomendasi As New List(Of RekomendasiUkm)()
        
        ' Add null checks for all data sources
        If jawaban Is Nothing Then
            System.Diagnostics.Debug.WriteLine("Error: jawaban is null")
            Return daftarRekomendasi
        End If
        
        Dim dataUkm = GetUkmData()
        If dataUkm Is Nothing Then
            System.Diagnostics.Debug.WriteLine("Error: dataUkm is null")
            Return daftarRekomendasi
        End If
        
        Dim deskripsiUkm = GetUkmDescriptions()
        If deskripsiUkm Is Nothing Then
            System.Diagnostics.Debug.WriteLine("Error: deskripsiUkm is null")
            Return daftarRekomendasi
        End If
        
        Dim petaRelevansi As Dictionary(Of Integer, List(Of String)) = GetQuestionToUkmMap()
        If petaRelevansi Is Nothing Then
            System.Diagnostics.Debug.WriteLine("Error: petaRelevansi is null")
            Return daftarRekomendasi
        End If

        ' Ambil aturan pengecualian UKM berdasarkan pertanyaan. UKM yang ada dalam daftar pengecualian
        ' untuk suatu pertanyaan akan di-skip jika mahasiswa menjawab > 3 (Tidak Setuju atau Sangat Tidak Setuju) pada pertanyaan tersebut.
        Dim pengecualianUkm As Dictionary(Of Integer, List(Of String)) = GetExclusionRules()
        
        ' Debug: Mencatat data UKM
        System.Diagnostics.Debug.WriteLine("\n=== PERHITUNGAN REKOMENDASI UKM (Weighted Scoring v6.0 + Mapping) ===")
        System.Diagnostics.Debug.WriteLine("Total UKM yang dimuat: " & dataUkm.Count)
        System.Diagnostics.Debug.WriteLine("Total jawaban yang diterima: " & jawaban.Count)
        
        ' Mencatat semua pertanyaan dan jawaban untuk verifikasi
        System.Diagnostics.Debug.WriteLine("\nJawaban yang sedang diproses:")
        For Each pasangan In jawaban
            System.Diagnostics.Debug.WriteLine("P" & pasangan.Key & ": " & pasangan.Value)
        Next
        
        ' Pengecualian khusus: Jika jawaban P20 = 5, tidak ada rekomendasi
        If jawaban.ContainsKey(20) AndAlso jawaban(20) = 5 Then
            System.Diagnostics.Debug.WriteLine("\nTidak ada rekomendasi karena jawaban P20 = 5")
            Return New List(Of RekomendasiUkm)()
        End If
        
        ' Hitung skor untuk setiap UKM
        For Each ukm In dataUkm
            Dim namaUkm As String = ""
            Try
                namaUkm = ukm.Key
                Dim bobotUkm As Integer() = ukm.Value
                
                ' Add null checks for UKM data
                If String.IsNullOrEmpty(namaUkm) Then
                    System.Diagnostics.Debug.WriteLine("Warning: UKM name is null or empty, skipping")
                    Continue For
                End If
                
                If bobotUkm Is Nothing OrElse bobotUkm.Length = 0 Then
                    System.Diagnostics.Debug.WriteLine("Warning: UKM weights are null or empty for " & namaUkm & ", skipping")
                    Continue For
                End If
                
                Dim totalSkor As Double = 0
                Dim maxSkor As Double = 0
                Dim kategoriPertanyaan = GetQuestionCategories()
                Dim kategoriUkm = GetUkmCategories()
                
                ' Add null checks for category data
                If kategoriPertanyaan Is Nothing Then
                    kategoriPertanyaan = New Dictionary(Of Integer, String)()
                End If
                
                If kategoriUkm Is Nothing Then
                    kategoriUkm = New Dictionary(Of String, List(Of String))()
                End If
            
                ' Debug: Tampilkan nama UKM
                System.Diagnostics.Debug.WriteLine(String.Format("\nMenghitung skor untuk UKM: {0}", namaUkm))

                ' Periksa aturan pengecualian: jika mahasiswa menjawab > 3 (tidak setuju) untuk pertanyaan tertentu
                ' dan UKM ini termasuk dalam daftar pengecualian untuk pertanyaan tersebut, maka UKM ini di-skip.
                Dim excluded As Boolean = False
                For Each pasangan In jawaban
                    Dim pid As Integer = pasangan.Key
                    Dim ansVal As Integer = pasangan.Value
                    If ansVal > 3 AndAlso pengecualianUkm IsNot Nothing AndAlso pengecualianUkm.ContainsKey(pid) Then
                        Dim listUkm As List(Of String) = pengecualianUkm(pid)
                        If listUkm IsNot Nothing AndAlso listUkm.Contains(namaUkm) Then
                            excluded = True
                            System.Diagnostics.Debug.WriteLine(String.Format("  UKM {0} dikecualikan karena jawaban P{1} = {2}", namaUkm, pid, ansVal))
                            Exit For
                        End If
                    End If
                Next
                If excluded Then
                    ' Skip perhitungan untuk UKM ini
                    Continue For
                End If

                ' Hitung skor untuk setiap pertanyaan
                For i As Integer = 0 To Math.Min(bobotUkm.Length - 1, 19)
                    Dim pertanyaanId As Integer = i + 1
                    Dim jawabanNilai As Integer = If(jawaban.ContainsKey(pertanyaanId), jawaban(pertanyaanId), 3) ' Default 3 jika tidak dijawab
                    Dim bobotNilai As Integer = bobotUkm(i)

                    ' Penyesuaian faktor relevansi berdasarkan pemetaan eksplisit:
                    ' Jika UKM relevan untuk pertanyaan ini, gunakan boost lebih besar (1.5).
                    ' Jika tidak relevan, kurangi bobot dengan faktor 0.8 agar pertanyaan yang tidak berkaitan tidak terlalu mempengaruhi.
                    Dim relevansiBoost As Double = 1.0
                    If petaRelevansi.ContainsKey(pertanyaanId) Then
                        Dim daftarRel As List(Of String) = petaRelevansi(pertanyaanId)
                        If daftarRel IsNot Nothing AndAlso daftarRel.Contains(namaUkm) Then
                            relevansiBoost = 1.5
                        Else
                            relevansiBoost = 0.8
                        End If
                    End If

                    ' Faktor boost kategori: jika kategori pertanyaan cocok dengan kategori UKM
                    Dim kategoriBoost As Double = 1.0
                    If kategoriPertanyaan.ContainsKey(pertanyaanId) Then
                        Dim kat As String = kategoriPertanyaan(pertanyaanId)
                        If kategoriUkm.ContainsKey(namaUkm) AndAlso kategoriUkm(namaUkm) IsNot Nothing AndAlso kategoriUkm(namaUkm).Contains(kat) Then
                            kategoriBoost = 1.15 ' boost 15% untuk kecocokan kategori
                        End If
                    End If

                    ' Hitung poin berdasarkan jawaban (1-5) -> (5-1 poin)
                    Dim poinJawaban As Integer = 6 - jawabanNilai

                    ' Hitung kontribusi skor untuk pertanyaan ini
                    totalSkor += (poinJawaban * bobotNilai) * relevansiBoost * kategoriBoost

                    ' Hitung skor maksimal yang mungkin untuk pertanyaan ini (5 * bobot * boost factors)
                    Dim maxPoinPertanyaan As Double = (5 * bobotNilai) * relevansiBoost * kategoriBoost
                    maxSkor += maxPoinPertanyaan

                    ' Debug: Tampilkan perhitungan per pertanyaan
                    System.Diagnostics.Debug.WriteLine(String.Format("  P{0}: Jawaban={1}, Bobot={2}, RelBoost={3}, KatBoost={4}, Poin={5}, SkorAkumulasi={6}, Maks={7}", _
                                                                  pertanyaanId, jawabanNilai, bobotNilai, relevansiBoost, kategoriBoost, poinJawaban, totalSkor, maxPoinPertanyaan))
                Next
            
            ' Hitung persentase kecocokan (0-100%)
            Dim persentaseKecocokan As Double = 0
            If maxSkor > 0 Then
                persentaseKecocokan = Math.Round((totalSkor / maxSkor) * 100, 2)
            End If
            
            ' Debug: Tampilkan hasil perhitungan
            System.Diagnostics.Debug.WriteLine(String.Format("  Total Skor: {0}, Maksimal: {1}, Kecocokan: {2}%", 
                                                          totalSkor, maxSkor, persentaseKecocokan))
            
            ' Tambahkan ke daftar rekomendasi jika memenuhi syarat minimal (>= 25%)
            If persentaseKecocokan >= 25 Then
                Dim deskripsi As String = If(deskripsiUkm.ContainsKey(namaUkm), deskripsiUkm(namaUkm), "Deskripsi tidak tersedia")
                daftarRekomendasi.Add(New RekomendasiUkm() With {
                    .Nama = namaUkm,
                    .Skor = CInt(persentaseKecocokan),
                    .Deskripsi = deskripsi
                })
                System.Diagnostics.Debug.WriteLine(String.Format("  UKM {0} DITAMBAHKAN dengan kecocokan {1}%", namaUkm, persentaseKecocokan))
            Else
                System.Diagnostics.Debug.WriteLine(String.Format("  UKM {0} TIDAK DITAMBAHKAN (kecocokan {1}% < 25%)", namaUkm, persentaseKecocokan))
            End If
            
            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine(String.Format("Error calculating score for UKM {0}: {1}", namaUkm, ex.Message))
                ' Continue to next UKM instead of failing completely
                Continue For
            End Try
        Next
        
        ' Urutkan berdasarkan persentase kecocokan tertinggi
        Dim rekomendasiTerurut = daftarRekomendasi.OrderByDescending(Function(r) r.Skor).ToList()
        
        ' Debug: Tampilkan daftar rekomendasi akhir
        System.Diagnostics.Debug.WriteLine("\n=== Daftar Rekomendasi Akhir (Terurut) ===")
        For i As Integer = 0 To Math.Min(rekomendasiTerurut.Count - 1, 9) ' Tampilkan top 10
            Dim r = rekomendasiTerurut(i)
            System.Diagnostics.Debug.WriteLine(String.Format("{0}. {1}: {2}%", i + 1, r.Nama, r.Skor))
        Next
        
        ' Kembalikan maksimal 5 rekomendasi teratas dengan kecocokan >= 30%
        If rekomendasiTerurut.Count > 0 Then
            ' Jika ada rekomendasi, ambil maksimal 5 teratas
            Return If(rekomendasiTerurut.Count > 5, rekomendasiTerurut.Take(5).ToList(), rekomendasiTerurut)
        Else
            ' Jika tidak ada yang memenuhi threshold 30%, kembalikan 2 teratas
            Dim semuaUrut = dataUkm.Keys.Select(Function(k) New RekomendasiUkm() With {
                .Nama = k,
                .Skor = 0,
                .Deskripsi = If(deskripsiUkm.ContainsKey(k), deskripsiUkm(k), "")
            }).OrderByDescending(Function(r) HitungSkorUkm(r.Nama, jawaban, dataUkm)).Take(2).ToList()
            
            ' Hitung ulang skor untuk 2 teratas
            For Each r In semuaUrut
                r.Skor = CInt(HitungPersentaseKecocokan(r.Nama, jawaban, dataUkm))
            Next
            
            System.Diagnostics.Debug.WriteLine("\nTidak ada rekomendasi dengan kecocokan >= 30%, mengembalikan 2 teratas:")
            For i As Integer = 0 To Math.Min(semuaUrut.Count - 1, 1)
                Dim r = semuaUrut(i)
                System.Diagnostics.Debug.WriteLine(String.Format("{0}. {1}: {2}%", i + 1, r.Nama, r.Skor))
            Next
            
            Return semuaUrut
        End If
    End Function
    
    ' Fungsi pembantu untuk menghitung skor UKM
    Private Function HitungSkorUkm(namaUkm As String, jawaban As Dictionary(Of Integer, Integer), dataUkm As Dictionary(Of String, Integer())) As Double
        If Not dataUkm.ContainsKey(namaUkm) Then Return 0
        
        Dim bobotUkm = dataUkm(namaUkm)
        Dim totalSkor As Double = 0
        
        For i As Integer = 0 To Math.Min(bobotUkm.Length - 1, 19)
            Dim pertanyaanId As Integer = i + 1
            Dim jawabanNilai As Integer = If(jawaban.ContainsKey(pertanyaanId), jawaban(pertanyaanId), 3) ' Default 3 jika tidak dijawab
            Dim bobotNilai As Integer = bobotUkm(i)
            
            ' Hitung poin berdasarkan jawaban (1-5) -> (5-1 poin)
            Dim poinJawaban As Integer = 6 - jawabanNilai
            
            ' Hitung kontribusi skor untuk pertanyaan ini
            totalSkor += poinJawaban * bobotNilai
        Next
        
        Return totalSkor
    End Function
    
    ' Fungsi pembantu untuk menghitung persentase kecocokan
    Private Function HitungPersentaseKecocokan(namaUkm As String, jawaban As Dictionary(Of Integer, Integer), dataUkm As Dictionary(Of String, Integer())) As Double
        If Not dataUkm.ContainsKey(namaUkm) Then Return 0
        
        Dim bobotUkm = dataUkm(namaUkm)
        Dim totalSkor As Double = 0
        Dim maxSkor As Double = 0
        
        For i As Integer = 0 To Math.Min(bobotUkm.Length - 1, 19)
            Dim pertanyaanId As Integer = i + 1
            Dim jawabanNilai As Integer = If(jawaban.ContainsKey(pertanyaanId), jawaban(pertanyaanId), 3) ' Default 3 jika tidak dijawab
            Dim bobotNilai As Integer = bobotUkm(i)
            
            ' Hitung poin berdasarkan jawaban (1-5) -> (5-1 poin)
            Dim poinJawaban As Integer = 6 - jawabanNilai
            
            ' Hitung kontribusi skor untuk pertanyaan ini
            totalSkor += poinJawaban * bobotNilai
            
            ' Hitung skor maksimal yang mungkin untuk pertanyaan ini (5 * bobot)
            maxSkor += 5 * bobotNilai
        Next
        
        ' Hitung persentase kecocokan (0-100%)
        If maxSkor > 0 Then
            Return Math.Round((totalSkor / maxSkor) * 100, 2)
        End If
        
        Return 0
    End Function
    
    ' Fungsi untuk memverifikasi perhitungan dengan data contoh
    Private Sub TestCalculation()
        ' Contoh jawaban mahasiswa untuk pengujian
        Dim jawabanContoh As New Dictionary(Of Integer, Integer)
            ' [migrated-note] {1, 5}, {2, 3}, {3, 2}, {4, 1}, {5, 2}, {6, 3}, {7, 4}, {8, 5}, {9, 1}, {10, 4},
            ' [migrated-note] {11, 4}, {12, 3}, {13, 1}, {14, 4}, {15, 1}, {16, 5}, {17, 4}, {18, 4}, {19, 4}, {20, 4}
        
        ' TES KHUSUS: Test kasus tidak suka sulap (nilai > 3)
        Dim jawabanTidakSukaSulap As New Dictionary(Of Integer, Integer)
            ' [migrated-note] {1, 3}, {2, 3}, {3, 3}, {4, 3}, {5, 3}, {6, 3}, {7, 3}, {8, 3}, {9, 3}, {10, 3},
            ' [migrated-note] {11, 3}, {12, 3}, {13, 4}, {14, 3}, {15, 3}, {16, 3}, {17, 3}, {18, 3}, {19, 3}, {20, 3}
        
        ' TES KHUSUS: Test kasus suka musik (nilai <= 3)
        Dim jawabanSukaMusik As New Dictionary(Of Integer, Integer)
            ' [migrated-note] {1, 1}, {2, 3}, {3, 3}, {4, 3}, {5, 3}, {6, 3}, {7, 3}, {8, 3}, {9, 3}, {10, 3},
            ' [migrated-note] {11, 3}, {12, 3}, {13, 3}, {14, 3}, {15, 3}, {16, 3}, {17, 3}, {18, 3}, {19, 3}, {20, 3}
        
        Dim dataUkm = GetUkmData()
        
        System.Diagnostics.Debug.WriteLine(vbCrLf & "=== TES PERHITUNGAN (Versi 4.0) ===")
        System.Diagnostics.Debug.WriteLine("Skala Jawaban: 1=Sangat Setuju, 2=Setuju, 3=Netral, 4=Tidak Setuju, 5=Sangat Tidak Setuju")
        System.Diagnostics.Debug.WriteLine("Menguji dengan jawaban contoh:")
        For Each jawaban In jawabanContoh
            System.Diagnostics.Debug.WriteLine("P" & jawaban.Key & ": " & jawaban.Value)
        Next
        
        ' Menggunakan aturan pengecualian dari method yang sudah dibuat
        Dim pengecualianUkm = GetExclusionRules()
        
        ' Menghitung kesesuaian untuk UKM-UKM kunci dari contoh dengan logika baru
        Dim daftarUkmUji = {"Citra Pesona (CP)", "Band Tarumanagara (BAR)", "Radio UNTAR", "Seni Teater Tarumanagara", "Fotografi (PFT)", "FESTA (Sulap)"}
        
        For Each namaUkm In daftarUkmUji
            If dataUkm.ContainsKey(namaUkm) Then
                Dim jumlahKesesuaian As Integer = 0
                Dim dikecualikan As Boolean = False
                Dim daftarBobot = dataUkm(namaUkm)
                
                ' Periksa pengecualian berdasarkan jawaban
                For Each jawaban In jawabanContoh
                    Dim indeksPertanyaan = jawaban.Key - 1
                    If indeksPertanyaan >= 0 AndAlso indeksPertanyaan < daftarBobot.Length Then
                        Dim bobot = daftarBobot(indeksPertanyaan)
                        Dim nilaiJawaban = jawaban.Value
                        
                        ' Periksa pengecualian khusus untuk pertanyaan ini
                        If pengecualianUkm.ContainsKey(jawaban.Key) AndAlso pengecualianUkm(jawaban.Key).Contains(namaUkm) Then
                            ' Jika nilai > 3 (4 atau 5), UKM dikecualikan
                            If nilaiJawaban > 3 Then
                                System.Diagnostics.Debug.WriteLine(String.Format("{0} - DIKECUALIKAN karena jawaban P{1} = {2} (> 3)", namaUkm, jawaban.Key, nilaiJawaban))
                                dikecualikan = True
                                Exit For ' Keluar dari loop karena UKM sudah dikecualikan
                            End If
                        End If
                        
                        ' Untuk pertanyaan 20, jika nilai = 5, semua UKM dikecualikan
                        If jawaban.Key = 20 AndAlso nilaiJawaban = 5 Then
                            System.Diagnostics.Debug.WriteLine(String.Format("{0} - DIKECUALIKAN karena jawaban P20 = 5", namaUkm))
                            dikecualikan = True
                            Exit For ' Keluar dari loop karena UKM sudah dikecualikan
                        End If
                    End If
                Next
                
                ' Jika UKM tidak dikecualikan, hitung kesesuaian
                If Not dikecualikan Then
                    For Each jawaban In jawabanContoh
                        Dim indeksPertanyaan = jawaban.Key - 1
                        If indeksPertanyaan >= 0 AndAlso indeksPertanyaan < daftarBobot.Length Then
                            Dim bobot = daftarBobot(indeksPertanyaan)
                            Dim nilaiJawaban = jawaban.Value
                            
                            ' Jika user setuju/netral (nilai <= 3) DAN UKM kuat di area ini (bobot >= 3), tambah kesesuaian
                            If nilaiJawaban <= 3 AndAlso bobot >= 3 Then
                                jumlahKesesuaian += 1
                                System.Diagnostics.Debug.WriteLine(String.Format("{0} - P{1}: Kesesuaian ditemukan (Jawaban={2}, Bobot={3})",
                                                                          namaUkm, jawaban.Key, nilaiJawaban, bobot))
                            End If
                        End If
                    Next
                    
                    System.Diagnostics.Debug.WriteLine(namaUkm & " - Kesesuaian: " & jumlahKesesuaian)
                    System.Diagnostics.Debug.WriteLine("KESIMPULAN: " & namaUkm & " " & If(jumlahKesesuaian >= 1, "AKAN", "TIDAK AKAN") & " direkomendasikan")
                Else
                    System.Diagnostics.Debug.WriteLine("KESIMPULAN: " & namaUkm & " TIDAK AKAN direkomendasikan (dikecualikan)")
                End If
            End If
        Next
        
        ' TES KHUSUS: Test FESTA dengan jawaban tidak suka sulap (nilai > 3)
        System.Diagnostics.Debug.WriteLine(vbCrLf & "=== TES KHUSUS: FESTA dengan tidak suka sulap (nilai > 3) ===")
        If dataUkm.ContainsKey("FESTA (Sulap)") Then
            Dim jumlahKesesuaianFesta As Integer = 0
            Dim dikecualikanFesta As Boolean = False
            Dim bobotFesta = dataUkm("FESTA (Sulap)")
            
            ' Periksa pengecualian untuk FESTA
            For Each jawaban In jawabanTidakSukaSulap
                If jawaban.Key = 13 AndAlso jawaban.Value > 3 Then ' Pertanyaan sulap (P13)
                    System.Diagnostics.Debug.WriteLine(String.Format("FESTA - DIKECUALIKAN karena jawaban P{0} = {1} (> 3) [PENTING!]", jawaban.Key, jawaban.Value))
                    dikecualikanFesta = True
                    Exit For
                End If
                
                ' Untuk pertanyaan 20, jika nilai = 5, semua UKM dikecualikan
                If jawaban.Key = 20 AndAlso jawaban.Value = 5 Then
                    System.Diagnostics.Debug.WriteLine(String.Format("FESTA - DIKECUALIKAN karena jawaban P20 = 5", jawaban.Key))
                    dikecualikanFesta = True
                    Exit For
                End If
            Next
            
            ' Jika FESTA tidak dikecualikan, hitung kesesuaian
            If Not dikecualikanFesta Then
                For Each jawaban In jawabanTidakSukaSulap
                    Dim indeksPertanyaan = jawaban.Key - 1
                    If indeksPertanyaan >= 0 AndAlso indeksPertanyaan < bobotFesta.Length Then
                        Dim bobot = bobotFesta(indeksPertanyaan)
                        Dim nilaiJawaban = jawaban.Value
                        
                        ' Jika user setuju/netral (nilai <= 3) DAN UKM kuat di area ini (bobot >= 3), tambah kesesuaian
                        If nilaiJawaban <= 3 AndAlso bobot >= 3 Then
                            jumlahKesesuaianFesta += 1
                            System.Diagnostics.Debug.WriteLine(String.Format("FESTA - P{0}: Kesesuaian ditemukan (Jawaban={1}, Bobot={2})",
                                                                      jawaban.Key, nilaiJawaban, bobot))
                        End If
                    End If
                Next
                
                System.Diagnostics.Debug.WriteLine("FESTA - Kesesuaian: " & jumlahKesesuaianFesta)
                System.Diagnostics.Debug.WriteLine("KESIMPULAN: FESTA " & If(jumlahKesesuaianFesta >= 1, "AKAN", "TIDAK AKAN") & " direkomendasikan")
            Else
                System.Diagnostics.Debug.WriteLine("KESIMPULAN: FESTA TIDAK AKAN direkomendasikan (dikecualikan)")
            End If
        End If
        
        ' TES KHUSUS: Test Band dengan jawaban suka musik (nilai <= 3)
        System.Diagnostics.Debug.WriteLine(vbCrLf & "=== TES KHUSUS: Band dengan suka musik (nilai <= 3) ===")
        If dataUkm.ContainsKey("Band Tarumanagara (BAR)") Then
            Dim jumlahKesesuaianBand As Integer = 0
            Dim dikecualikanBand As Boolean = False
            Dim bobotBand = dataUkm("Band Tarumanagara (BAR)")
            
            ' Periksa pengecualian untuk Band
            For Each jawaban In jawabanSukaMusik
                If jawaban.Key = 1 AndAlso jawaban.Value > 3 Then ' Pertanyaan musik (P1)
                    System.Diagnostics.Debug.WriteLine(String.Format("Band - DIKECUALIKAN karena jawaban P{0} = {1} (> 3) [PENTING!]", jawaban.Key, jawaban.Value))
                    dikecualikanBand = True
                    Exit For
                End If
                
                ' Untuk pertanyaan 20, jika nilai = 5, semua UKM dikecualikan
                If jawaban.Key = 20 AndAlso jawaban.Value = 5 Then
                    System.Diagnostics.Debug.WriteLine(String.Format("Band - DIKECUALIKAN karena jawaban P20 = 5", jawaban.Key))
                    dikecualikanBand = True
                    Exit For
                End If
            Next
            
            ' Jika Band tidak dikecualikan, hitung kesesuaian
            If Not dikecualikanBand Then
                For Each jawaban In jawabanSukaMusik
                    Dim indeksPertanyaan = jawaban.Key - 1
                    If indeksPertanyaan >= 0 AndAlso indeksPertanyaan < bobotBand.Length Then
                        Dim bobot = bobotBand(indeksPertanyaan)
                        Dim nilaiJawaban = jawaban.Value
                        
                        ' Jika user setuju/netral (nilai <= 3) DAN UKM kuat di area ini (bobot >= 3), tambah kesesuaian
                        If nilaiJawaban <= 3 AndAlso bobot >= 3 Then
                            jumlahKesesuaianBand += 1
                            If jawaban.Key = 1 Then ' Pertanyaan musik
                                System.Diagnostics.Debug.WriteLine(String.Format("Band - P{0} (Musik): Kesesuaian ditemukan (Jawaban={1}, Bobot={2}) [PENTING!]",
                                                                          jawaban.Key, nilaiJawaban, bobot))
                            Else
                                System.Diagnostics.Debug.WriteLine(String.Format("Band - P{0}: Kesesuaian ditemukan (Jawaban={1}, Bobot={2})",
                                                                          jawaban.Key, nilaiJawaban, bobot))
                            End If
                        End If
                    End If
                Next
                
                System.Diagnostics.Debug.WriteLine("Band - Kesesuaian: " & jumlahKesesuaianBand)
                System.Diagnostics.Debug.WriteLine("KESIMPULAN: Band " & If(jumlahKesesuaianBand >= 1, "AKAN", "TIDAK AKAN") & " direkomendasikan")
            Else
                System.Diagnostics.Debug.WriteLine("KESIMPULAN: Band TIDAK AKAN direkomendasikan (dikecualikan)")
            End If
        End If
    End Sub
    
    ' Method untuk mendapatkan kode UKM berdasarkan nama UKM
    ' Fungsi helper untuk menerjemahkan nama UKM ke kode numerik.
    ' Kode ini digunakan untuk disimpan di kolom jawaban pada tbl_rekom_jawaban.
    ' Pastikan daftar mapping nama -> kode ini konsisten dengan tabel master UKM di database.
    ' Fungsi helper untuk menerjemahkan nama UKM yang dibaca dari rekomendasi menjadi kode numerik.
    ' Kode numerik ini sesuai dengan kolom `kode_ukm` di basis data dan diperlukan saat menyimpan rekomendasi.
    ' Jika nama UKM tidak dikenali, fungsi ini mengembalikan 0 sehingga baris tersebut tidak akan disimpan.
    Private Function AmbilKodeUkm(namaUkm As String) As Integer
        ' Pastikan nama tidak null dan hilangkan spasi di awal/akhir
        Dim namaInputUkm As String = If(namaUkm, String.Empty).Trim()

        ' Daftar master UKM beserta kode resminya.  Nilai ini harus konsisten dengan tabel master UKM di database.
        Dim petaMasterUkm As New Dictionary(Of String, Integer)(StringComparer.OrdinalIgnoreCase)
            petaMasterUkm.Add("Band Tarumanagara (BAR)", 1)
            petaMasterUkm.Add("Seni Teater Tarumanagara (SENTRA)", 2)
            petaMasterUkm.Add("Form Ukhuwah Tarumanagara (FUT)", 3)
            petaMasterUkm.Add("Persekutuan Oikoumene Universitas Tarumanagara (POUT)", 4)
            petaMasterUkm.Add("Liga Tenis Meja UNTAR (LTMU)", 5)
            petaMasterUkm.Add("Liga Bulu Tangkis Universitas Tarumanagara (LBUT)", 6)
            petaMasterUkm.Add("Citra Pesona (CP)", 8)
            petaMasterUkm.Add("Liga Voli Tarumanagara (LIVOSTA)", 9)
            petaMasterUkm.Add("Liga Futsal Tarumanagara", 10)
            petaMasterUkm.Add("Liga Basket Tarumanagara (LIBAMA)", 11)
            petaMasterUkm.Add("Federasi Sulap Tarumanagara (FESTA)", 12)
            petaMasterUkm.Add("Paduan Suara Universitas Tarumanagara (PSUT)", 13)
            petaMasterUkm.Add("Perhimpunan Fotografi Tarumanagara (PFT)", 14)
            petaMasterUkm.Add("Radio Universitas Tarumanagara-", 15)
            petaMasterUkm.Add("Soushin Tarumanagara Nihon Bu", 16)
            petaMasterUkm.Add("Tarumanagara English Club (TEC)", 17)
            petaMasterUkm.Add("Wacana Mahasiswa Ksatria Tarumanagara (WMKT)", 18)
            petaMasterUkm.Add("Mahasiswa Hukum Pecinta Alam (MAHUPA)", 19)
            petaMasterUkm.Add("Mahasiswa Teknik Pecinta Alam (MARSIPALA)", 20)
            petaMasterUkm.Add("Mahasiswa Ekonomi Gemar Alam (MEGA)", 21)
            petaMasterUkm.Add("KMK ADHYATMAKA", 22)
            petaMasterUkm.Add("Keluarga Besar Mahasiswa Konghucu (KBMK)", 23)
            petaMasterUkm.Add("Keluarga Mahasiswa Buddha Dharmayana (KMB Dharmayana)", 24)
            petaMasterUkm.Add("Taekwondo", 25)
            petaMasterUkm.Add("Wushu", 26)
            petaMasterUkm.Add("Jujitsu", 27)

        ' Peta alias: ini berisi variasi nama UKM yang mungkin muncul di UI atau data.
        ' Setiap alias diarahkan ke kode yang sama dengan entri master yang relevan.
        Dim petaAliasUkm As New Dictionary(Of String, Integer)(StringComparer.OrdinalIgnoreCase)
            ' Musik dan seni
            petaAliasUkm.Add("Seni Teater Tarumanagara", 2)
            petaAliasUkm.Add("Band Tarumanagara", 1)
            petaAliasUkm.Add("Paduan Suara (PSUT)", 13)
            petaAliasUkm.Add("Fotografi (PFT)", 14)
            petaAliasUkm.Add("FESTA (Sulap)", 12)
            petaAliasUkm.Add("Radio UNTAR", 15)

            ' Kerohanian
            petaAliasUkm.Add("FUT (Ukhuwah Muslim)", 3)
            petaAliasUkm.Add("POUT (Kerohanian Kristen)", 4)
            petaAliasUkm.Add("KMK Adhyatmaka (Katolik)", 22)
            petaAliasUkm.Add("KBMK (Konghucu)", 23)
            petaAliasUkm.Add("KMB Dharmayana (Buddha)", 24)

            ' Olahraga tim/individu
            petaAliasUkm.Add("Liga Tenis Meja (LTMU)", 5)
            petaAliasUkm.Add("LBUT (Bulutangkis)", 6)
            petaAliasUkm.Add("Liga Voli (LIVOSTA)", 9)
            petaAliasUkm.Add("Liga Basket (LIBAMA)", 11)
            petaAliasUkm.Add("Liga Futsal", 10)
            petaAliasUkm.Add("Taekwondo", 25)
            petaAliasUkm.Add("Wushu", 26)
            petaAliasUkm.Add("Jujitsu Tarumanagara", 27)

            ' Bahasa dan budaya
            petaAliasUkm.Add("Nihon Bu (Jepang)", 16)
            petaAliasUkm.Add("English Club (TEC)", 17)

            ' Organisasi / Diskusi
            petaAliasUkm.Add("WMKT", 18)

            ' Alam dan petualangan
            petaAliasUkm.Add("MAHUPA", 19)
            petaAliasUkm.Add("MARSIPALA", 20)
            petaAliasUkm.Add("MEGA", 21)

            ' Lain-lain (Citra Pesona sudah terpetakan di master)
            petaAliasUkm.Add("Citra Pesona (CP)", 8)

        ' 1) Pencarian persis di daftar master
        If petaMasterUkm.ContainsKey(namaInputUkm) Then
            Return petaMasterUkm(namaInputUkm)
        End If

        ' 2) Pencarian persis di daftar alias
        If petaAliasUkm.ContainsKey(namaInputUkm) Then
            Return petaAliasUkm(namaInputUkm)
        End If

        ' 3) Pencarian sebagian: cocokkan jika salah satu string mengandung yang lain.
        ' Ini menangani kasus seperti "Liga Futsal" vs "Liga Futsal Tarumanagara".
        For Each key As String In petaMasterUkm.Keys
            If key.IndexOf(namaInputUkm, StringComparison.OrdinalIgnoreCase) >= 0 OrElse namaInputUkm.IndexOf(key, StringComparison.OrdinalIgnoreCase) >= 0 Then
                Return petaMasterUkm(key)
            End If
        Next

        ' 4) Jika tidak ditemukan, kembalikan 0 (menandakan kode tidak valid)
        Return 0
    End Function
    
    ' Method untuk menyimpan jawaban ke database
    ' Menyimpan jawaban kuesioner ke tabel tbl_rekom_jawaban.
    ' Untuk setiap pertanyaan (ID 1–20) fungsi memeriksa apakah sudah ada entri untuk NIM yang sama;
    ' jika ya, jawaban diperbarui; jika tidak, jawaban baru ditambahkan.
    ' Data disimpan dalam satu transaksi untuk menjaga konsistensi.
    ' Menyimpan jawaban kuesioner ke database.
    Private Function SimpanJawabanKeDatabase(jawaban As Dictionary(Of Integer, Integer)) As Boolean
            ' Debug: Log the answers being saved
            System.Diagnostics.Debug.WriteLine("=== DEBUG: SimpanJawabanKeDatabase ===")
            System.Diagnostics.Debug.WriteLine("Jumlah jawaban: " & jawaban.Count)
            Try
            ' Gunakan koneksi dari conadmawa.ascx
            bukadoangadmawa()
            
            ' Mulai transaksi
            Dim transaction As Data.OleDb.OleDbTransaction = cnadmawa.BeginTransaction()
            
            Try
                ' Simpan setiap jawaban ke dalam tabel jawaban. Menggunakan nama tabel dari konstanta
                ' dan menamai variabel SQL agar lebih mudah dipahami.
                For Each answer In jawaban
                    ' Cek apakah jawaban sudah ada untuk NIM dan pertanyaan tertentu
                    Dim sqlCek As String = String.Format("SELECT COUNT(*) FROM {0} WHERE nim='{1}' AND id_pertanyaan={2}", TABEL_JAWABAN, Session("idlintar"), answer.Key)
                    Dim cmdCek As New Data.OleDb.OleDbCommand(sqlCek, cnadmawa, transaction)
                    Dim jumlah As Integer = CInt(cmdCek.ExecuteScalar())
                    
                    If jumlah > 0 Then
                        ' Update jawaban yang sudah ada
                        If answer.Key = 22 Then
                            ' Untuk pertanyaan penyakit bawaan (id=22), update kolom penyakitbawaan
                            Dim penyakitDetail As String = ""
                            If hdnDetailPenyakit IsNot Nothing Then
                                penyakitDetail = hdnDetailPenyakit.Value.Trim()
                            End If
                            System.Diagnostics.Debug.WriteLine("Updating disease info - jawaban: " & answer.Value & ", penyakitbawaan: " & penyakitDetail)
                            Dim sqlUpdatePenyakit As String = String.Format("UPDATE {0} SET jawaban={1}, penyakitbawaan='{2}' WHERE nim='{3}' AND id_pertanyaan={4}", TABEL_JAWABAN, answer.Value, penyakitDetail.Replace("'", "''"), Session("idlintar"), answer.Key)
                            Dim cmdUpdatePenyakit As New Data.OleDb.OleDbCommand(sqlUpdatePenyakit, cnadmawa, transaction)
                            cmdUpdatePenyakit.ExecuteNonQuery()
                        Else
                            ' Update jawaban biasa
                            Dim sqlUpdate As String = String.Format("UPDATE {0} SET jawaban={1} WHERE nim='{2}' AND id_pertanyaan={3}", TABEL_JAWABAN, answer.Value, Session("idlintar"), answer.Key)
                            Dim cmdUpdate As New Data.OleDb.OleDbCommand(sqlUpdate, cnadmawa, transaction)
                            cmdUpdate.ExecuteNonQuery()
                        End If
                    Else
                        ' Insert jawaban baru
                        If answer.Key = 22 Then
                            ' Untuk pertanyaan penyakit bawaan (id=22), insert dengan kolom penyakitbawaan
                            Dim penyakitDetail As String = ""
                            If hdnDetailPenyakit IsNot Nothing Then
                                penyakitDetail = hdnDetailPenyakit.Value.Trim()
                            End If
                            System.Diagnostics.Debug.WriteLine("Inserting disease info - jawaban: " & answer.Value & ", penyakitbawaan: " & penyakitDetail)
                            Dim sqlTambahPenyakit As String = String.Format("INSERT INTO {0} (nim, id_pertanyaan, jawaban, penyakitbawaan) VALUES ('{1}', {2}, {3}, '{4}')", TABEL_JAWABAN, Session("idlintar"), answer.Key, answer.Value, penyakitDetail.Replace("'", "''"))
                            Dim cmdTambahPenyakit As New Data.OleDb.OleDbCommand(sqlTambahPenyakit, cnadmawa, transaction)
                            cmdTambahPenyakit.ExecuteNonQuery()
                        Else
                            ' Insert jawaban biasa
                            Dim sqlTambah As String = String.Format("INSERT INTO {0} (nim, id_pertanyaan, jawaban) VALUES ('{1}', {2}, {3})", TABEL_JAWABAN, Session("idlintar"), answer.Key, answer.Value)
                            Dim cmdTambah As New Data.OleDb.OleDbCommand(sqlTambah, cnadmawa, transaction)
                            cmdTambah.ExecuteNonQuery()
                        End If
                    End If
                Next
                
                ' Commit transaksi jika semua berhasil
                transaction.Commit()
                Return True
                
            Catch ex As Exception
                ' Rollback transaksi jika terjadi error
                transaction.Rollback()
                Throw
            End Try
            
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Gagal menyimpan jawaban ke database: " & ex.Message)
            litPesan.Text = String.Format("<div class='alert alert-danger'>Gagal menyimpan jawaban: {0}</div>", ex.Message)
            Return False
            
        Finally
            ' Pastikan koneksi ditutup
            tutupadmawa()
        End Try
    End Function

    ' --------------------------------------------------------------------------------------------------
    ' Method untuk menyimpan hasil rekomendasi UKM ke tabel tbl_rekom_jawaban.
    ' Fungsi ini menyimpan hingga 5 rekomendasi teratas ke dalam tabel yang sama dengan jawaban,
    ' menggunakan id_pertanyaan fiktif (1001–1005) untuk membedakan data rekomendasi dari jawaban kuesioner.
    ' Nilai jawaban yang disimpan adalah kode UKM yang dihasilkan dari fungsi AmbilKodeUkm.
    ' Jika entri dengan NIM dan id_pertanyaan yang sama sudah ada, maka data akan diperbarui; jika tidak, data baru akan ditambahkan.
    ' Menyimpan rekomendasi UKM ke tabel tbl_rekom_jawaban.
    ' Setiap UKM disimpan dengan id_pertanyaan fiktif mulai dari 1001.
    ' Jika entri sudah ada untuk NIM dan id_pertanyaan tersebut, maka diperbarui; jika tidak, dibuat entri baru.
    ' Fungsi ini kini menyimpan seluruh rekomendasi (tidak hanya lima teratas) sehingga UKM dengan skor sama tetap dicatat.
    ' Menyimpan hasil rekomendasi UKM ke database.
    Private Function SimpanRekomendasiKeDatabase(ByVal rekomendasiList As List(Of RekomendasiUkm)) As Boolean
        ' Tidak ada rekomendasi untuk disimpan
        If rekomendasiList Is Nothing OrElse rekomendasiList.Count = 0 Then
            System.Diagnostics.Debug.WriteLine("Tidak ada rekomendasi untuk disimpan")
            Return True
        End If

        ' Dapatkan NIM dari session
        Dim nim As String = ""
        
        ' Coba dapatkan NIM dari berbagai kemungkinan session variable
        If Session("idlintar") IsNot Nothing Then
            nim = Session("idlintar").ToString().Trim()
        ElseIf Session("UserId") IsNot Nothing Then
            nim = Session("UserId").ToString().Trim()
        ElseIf Session("student_id") IsNot Nothing Then
            nim = Session("student_id").ToString().Trim()
        ElseIf Session("StudentId") IsNot Nothing Then
            nim = Session("StudentId").ToString().Trim()
        End If
        
        ' Jika masih kosong, gunakan nilai default untuk testing (HANYA UNTUK DEVELOPMENT)
        If String.IsNullOrEmpty(nim) Then
            System.Diagnostics.Debug.WriteLine("Peringatan: Session idlintar tidak ditemukan, menggunakan NIM default untuk testing")
            nim = "TEST" & DateTime.Now.ToString("HHmmss")
        End If
        
        System.Diagnostics.Debug.WriteLine("Menggunakan NIM: " & nim)

        Try
            ' Gunakan koneksi dari conadmawa.ascx
            bukadoangadmawa()
            
            ' Mulai transaksi
            Dim transaction As Data.OleDb.OleDbTransaction = cnadmawa.BeginTransaction()
            
            Try
                ' Log sebelum menghapus rekomendasi lama
                System.Diagnostics.Debug.WriteLine("Menghapus rekomendasi lama untuk NIM: " & nim)
                
                ' Hapus rekomendasi lama untuk NIM ini
                Dim sqlHapus As String = "DELETE FROM " & TABEL_REKOMENDASI & " WHERE nim = ?"
                Dim cmdHapus As New Data.OleDb.OleDbCommand(sqlHapus, cnadmawa, transaction)
                cmdHapus.Parameters.AddWithValue("@nim", nim)
                Dim deletedRows = cmdHapus.ExecuteNonQuery()
                
                System.Diagnostics.Debug.WriteLine("Menghapus " & deletedRows & " rekomendasi lama")
                
                ' Simpan rekomendasi baru
                System.Diagnostics.Debug.WriteLine("Menyimpan " & rekomendasiList.Count & " rekomendasi baru")
                
                For Each rec In rekomendasiList
                    ' Dapatkan kode_ukm dari nama UKM
                    Dim kodeUkm As Integer = AmbilKodeUkm(rec.Nama)
                    
                    ' Jika kode UKM valid (tidak 0), simpan ke database
                    If kodeUkm > 0 Then
                        ' Gunakan parameterized query untuk menghindari SQL injection
                    Dim sqlSimpan As String = "INSERT INTO " & TABEL_REKOMENDASI & " (nim, kode_ukm) VALUES (?, ?)"
                    Dim cmdSimpan As New Data.OleDb.OleDbCommand(sqlSimpan, cnadmawa, transaction)
                    
                    ' Gunakan NIM yang sudah diambil dari session
                    cmdSimpan.Parameters.AddWithValue("@nim", nim)
                    cmdSimpan.Parameters.AddWithValue("@kode_ukm", kodeUkm)
                    
                    Dim rowsAffected = cmdSimpan.ExecuteNonQuery()
                        
                        ' Debug log
                        System.Diagnostics.Debug.WriteLine(String.Format("Disimpan rekomendasi: {0} (kode: {1}, baris terpengaruh: {2})", 
                                                                     rec.Nama, kodeUkm, rowsAffected))
                    Else
                        System.Diagnostics.Debug.WriteLine(String.Format("Peringatan: Kode UKM tidak ditemukan untuk {0}", rec.Nama))
                    End If
                Next
                
                ' Commit transaksi jika semua berhasil
                transaction.Commit()
                System.Diagnostics.Debug.WriteLine("Berhasil menyimpan semua rekomendasi")
                Return True
                
            Catch ex As Exception
                ' Rollback transaksi jika terjadi error
                transaction.Rollback()
                System.Diagnostics.Debug.WriteLine("Error saat menyimpan rekomendasi: " & ex.Message)
                System.Diagnostics.Debug.WriteLine("Stack Trace: " & ex.StackTrace)
                litPesan.Text = String.Format("<div class='alert alert-danger'>Gagal menyimpan rekomendasi: {0}</div>", ex.Message)
                Return False
            End Try
            
        Catch ex As Exception
            System.Diagnostics.Debug.WriteLine("Gagal menyimpan rekomendasi ke database: " & ex.Message)
            System.Diagnostics.Debug.WriteLine("Stack Trace: " & ex.StackTrace)
            litPesan.Text = String.Format("<div class='alert alert-danger'>Gagal menyimpan rekomendasi: {0}</div>", ex.Message)
            Return False
            
        Finally
            ' Pastikan koneksi ditutup
            tutupadmawa()
        End Try
    End Function

    Protected Sub Page_Load(ByVal sender As Object, ByVal e As System.EventArgs) Handles Me.Load
        ' Log semua session yang tersedia untuk debugging
        System.Diagnostics.Debug.WriteLine("=== DEBUG: Session Values ===")
        For Each key As String In Session.Keys
            System.Diagnostics.Debug.WriteLine(String.Format("Session['{0}'] = '{1}'", key, Session(key)))
        Next
        System.Diagnostics.Debug.WriteLine("==========================")
        
        If Not IsPostBack Then
            LoadPertanyaan()
            
            ' Only run test calculation in debug mode
            #If DEBUG Then
            TestCalculation()
            #End If
        End If
        
        ' Check if biodata was just saved and clear the session flag
        If Session("BiodataSaved") IsNot Nothing AndAlso Session("BiodataSaved").ToString() = "true" Then
            Session.Remove("BiodataSaved")
        End If
    End Sub
    
    Private Sub LoadPertanyaan()
        Try
            ' Mengambil pertanyaan dari database
            Dim daftarPertanyaan As List(Of String) = GetQuestionsFromDatabase()
            
            ' Simpan pertanyaan di ViewState untuk digunakan di client-side
            ViewState("Questions") = daftarPertanyaan
            
            ' Simpan pertanyaan ke hidden field untuk digunakan di JavaScript
            Dim serializer As New System.Web.Script.Serialization.JavaScriptSerializer()
            Dim pertanyaanJson As String = serializer.Serialize(daftarPertanyaan)
            hdnQuestions.Value = pertanyaanJson
            
            ' Bind ke Repeater untuk data binding
            rptPertanyaan.DataSource = daftarPertanyaan.Select(Function(q, i) New With {
                .ID = i + 1,
                .Pertanyaan = q
            }).ToList()
            rptPertanyaan.DataBind()
            
            ' Debug: Log informasi pertanyaan yang dimuat
            System.Diagnostics.Debug.WriteLine("LoadPertanyaan: Berhasil memuat " & daftarPertanyaan.Count & " pertanyaan")
            
        Catch ex As Exception
            ' Tampilkan pesan error jika terjadi masalah
            litPesan.Text = "<div class='alert alert-danger'>Error memuat pertanyaan: " & Server.HtmlEncode(ex.Message) & "</div>"
            System.Diagnostics.Debug.WriteLine("LoadPertanyaan Error: " & ex.Message)
        End Try
    End Sub
    
    ' Event handler yang dipanggil saat setiap item pada Repeater diikat dengan data
    Protected Sub rptPertanyaan_ItemDataBound(ByVal sender As Object, ByVal e As RepeaterItemEventArgs)
        ' Cek apakah item yang sedang diproses adalah item data (bukan header/footer)
        If e.Item.ItemType = ListItemType.Item OrElse e.Item.ItemType = ListItemType.AlternatingItem Then
            ' Dapatkan data baris yang sedang diproses
            Dim barisData As Object = DirectCast(e.Item.DataItem, Object)
            Dim idPertanyaan As Integer = barisData.ID
            
            ' Daftar opsi jawaban yang tersedia untuk setiap pertanyaan
            Dim daftarPilihanJawaban As New List(Of String) From {
                "Sangat Setuju",
                "Setuju",
                "Ragu-Ragu",
                "Tidak Setuju",
                "Sangat Tidak Setuju"
            }
            
            ' Temukan kontrol RadioButtonList di dalam template dan isi dengan opsi jawaban
            Dim daftarJawaban As RadioButtonList = DirectCast(e.Item.FindControl("rblJawaban"), RadioButtonList)
            daftarJawaban.DataSource = daftarPilihanJawaban
            daftarJawaban.DataBind()
            
            ' Setel atribut kustom untuk mengidentifikasi pertanyaan yang sesuai dengan RadioButtonList ini
            daftarJawaban.Attributes("data-id-pertanyaan") = idPertanyaan.ToString()
        End If
    End Sub
    
    Protected Sub btnProcessAnswers_Click(sender As Object, e As EventArgs)
        Try
            ' Clear any previous messages
            litPesan.Text = ""
            
            ' Check if user is logged in (check multiple possible session variable names)
            Dim nim As String = ""
            If Session IsNot Nothing Then
                ' Debug: Log all session variables to help identify the correct one
                System.Diagnostics.Debug.WriteLine("=== SESSION DEBUG ===")
                For Each key As String In Session.Keys
                    System.Diagnostics.Debug.WriteLine("Session[" & key & "] = " & If(Session(key), "NULL"))
                Next
                System.Diagnostics.Debug.WriteLine("=== END SESSION DEBUG ===")
                
                ' Try various possible session variable names
                If Session("NIM") IsNot Nothing Then
                    nim = Session("NIM").ToString()
                ElseIf Session("nim") IsNot Nothing Then
                    nim = Session("nim").ToString()
                ElseIf Session("username") IsNot Nothing Then
                    nim = Session("username").ToString()
                ElseIf Session("Username") IsNot Nothing Then
                    nim = Session("Username").ToString()
                ElseIf Session("user_id") IsNot Nothing Then
                    nim = Session("user_id").ToString()
                ElseIf Session("UserId") IsNot Nothing Then
                    nim = Session("UserId").ToString()
                ElseIf Session("student_id") IsNot Nothing Then
                    nim = Session("student_id").ToString()
                ElseIf Session("StudentId") IsNot Nothing Then
                    nim = Session("StudentId").ToString()
                End If
            End If
            
            ' For testing purposes, temporarily bypass login check
            ' Remove this section after identifying the correct session variable
            If String.IsNullOrEmpty(nim) Then
                System.Diagnostics.Debug.WriteLine("No valid session found, using test NIM")
                nim = "TEST123" ' Temporary test value
            End If
            
            ' Original login check (commented out for testing)
            'If String.IsNullOrEmpty(nim) Then
            '    litPesan.Text = "<div class='alert alert-warning'><i class='fas fa-exclamation-triangle me-2'></i>Anda harus login terlebih dahulu untuk menggunakan fitur ini.</div>"
            '    Return
            'End If
            
            ' Register JavaScript to scroll to results
            Page.ClientScript.RegisterStartupScript(Me.GetType(), "ScrollToResults", "setTimeout(function() { $('html, body').animate({ scrollTop: $('#litPesan').offset().top - 20 }, 500); }, 100);", True)
            
            ' Debug: Log that the button click was received
            System.Diagnostics.Debug.WriteLine("btnProcessAnswers_Click started")
            
            ' Disease information will be saved as part of the main answer saving process
            ' No separate saving needed here as it's handled in SimpanJawabanKeDatabase method

            ' Get answers from hidden field with null check
            Dim answersJson As String = ""
            If hdnAnswers IsNot Nothing Then
                answersJson = hdnAnswers.Value
            End If
            
            ' Log received data for debugging
            System.Diagnostics.Debug.WriteLine("Received jawabanMahasiswa JSON: " & answersJson)
            
            If String.IsNullOrEmpty(answersJson) Then
                litPesan.Text = "<div class='alert alert-danger'><i class='fas fa-exclamation-circle me-2'></i>Tidak ada jawaban yang ditemukan. Silakan isi semua pertanyaan dan coba lagi.</div>"
                Return
            End If
            
            ' Parse answers
            Dim jawabanMahasiswa As New Dictionary(Of Integer, Integer)()
            Try
                ' Log the raw JSON for debugging
                System.Diagnostics.Debug.WriteLine("Raw jawabanMahasiswa JSON: " & answersJson)
                
                ' Clean and prepare the JSON string
                answersJson = answersJson.Trim()
                System.Diagnostics.Debug.WriteLine("Original JSON: " & answersJson)
                
                ' Try to fix common JSON formatting issues
                If Not answersJson.StartsWith("{") Then answersJson = "{" & answersJson
                If Not answersJson.EndsWith("}") Then answersJson = answersJson & "}"
                answersJson = answersJson.Replace("'", """")
                
                ' Log the cleaned JSON
                System.Diagnostics.Debug.WriteLine("Cleaned JSON: " & answersJson)
                
                ' Deserialize the JSON with error handling
                Dim stringAnswers As New Dictionary(Of String, String)()
                Try
                    Dim jss As New System.Web.Script.Serialization.JavaScriptSerializer()
                    stringAnswers = jss.Deserialize(Of Dictionary(Of String, String))(answersJson)
                Catch ex As Exception
                    System.Diagnostics.Debug.WriteLine("JSON Deserialization Error: " & ex.Message)
                    System.Diagnostics.Debug.WriteLine("Stack Trace: " & ex.StackTrace)
                    litPesan.Text = "<div class='alert alert-danger'><i class='fas fa-exclamation-circle me-2'></i>Terjadi kesalahan saat memproses jawaban. Format jawaban tidak valid.</div>"
                    Return
                End Try
                
                    ' Convert string keys to integers and ensure answer values are in range 1-5
                    ' Detect whether the answers object uses zero-based keys (0..n-1) or one-based keys (1..n).
                    Dim offset As Integer = 0
                    If stringAnswers IsNot Nothing AndAlso stringAnswers.ContainsKey("0") Then
                        ' Front-end stores answers with zero-based indices; adjust to one-based for backend.
                        offset = 1
                    End If
                    For Each pasangan In stringAnswers
                        Dim idPertanyaan As Integer
                        Dim answerValue As Integer

                        ' Parse question ID and answer value
                        If Integer.TryParse(pasangan.Key, idPertanyaan) AndAlso Integer.TryParse(pasangan.Value, answerValue) Then
                            ' Ensure answer is within valid range (1-5)
                            answerValue = Math.Max(1, Math.Min(5, answerValue))
                            ' Shift zero-based keys to one-based if needed.
                            Dim adjustedId As Integer = idPertanyaan + offset
                            ' Avoid duplicate keys if both zero-based and one-based keys exist; zero-based keys take precedence.
                            jawabanMahasiswa(adjustedId) = answerValue

                            ' Log each answer for debugging
                            System.Diagnostics.Debug.WriteLine("Q" & adjustedId & ": " & answerValue)
                        End If
                    Next
                
                ' Log parsed answers count for debugging
                System.Diagnostics.Debug.WriteLine("Successfully parsed " & jawabanMahasiswa.Count & " jawabanMahasiswa")
                
                ' If no valid answers were found, show error
                If jawabanMahasiswa.Count = 0 Then
                    litPesan.Text = "<div class='alert alert-danger'><i class='fas fa-exclamation-circle me-2'></i>Tidak ada jawaban yang valid ditemukan. Silakan coba lagi.</div>"
                    Return
                End If
                
            Catch ex As Exception
                Dim errorMsg = "Error processing jawabanMahasiswa: " & ex.Message
                System.Diagnostics.Debug.WriteLine(errorMsg)
                System.Diagnostics.Debug.WriteLine("Stack Trace: " & ex.StackTrace)
                litPesan.Text = "<div class='alert alert-danger'><i class='fas fa-exclamation-circle me-2'></i>Terjadi kesalahan saat memproses jawaban. Silakan coba lagi.</div>"
                Return
            End Try
            
            ' Log the raw answers JSON for debugging
            System.Diagnostics.Debug.WriteLine("Raw jawabanMahasiswa JSON: " & hdnAnswers.Value)
            
            ' Check if we have enough answers
            If jawabanMahasiswa.Count < 5 Then ' Require at least 5 answers
                System.Diagnostics.Debug.WriteLine("Not enough jawabanMahasiswa. Only found: " & jawabanMahasiswa.Count)
                litPesan.Text = "<div class='alert alert-warning'><i class='fas fa-exclamation-triangle me-2'></i>Mohon jawab minimal 5 pertanyaan untuk mendapatkan rekomendasi.</div>"
                Return
            End If
            
            ' Tambahkan jawaban untuk pertanyaan khusus (id 21 & 22) dari hidden field
            Try
                Dim genderVal As String = ""
                Dim penyakitVal As String = ""
                Dim detailPenyakitVal As String = ""
                If hdnGender IsNot Nothing Then genderVal = hdnGender.Value
                If hdnPenyakit IsNot Nothing Then penyakitVal = hdnPenyakit.Value
                If hdnDetailPenyakit IsNot Nothing Then detailPenyakitVal = hdnDetailPenyakit.Value

                ' Simpan gender: 1 untuk Laki-laki, 2 untuk Perempuan; atau kosong jika tidak dipilih
                Dim genderInt As Integer = 0
                If Not String.IsNullOrEmpty(genderVal) Then
                    If genderVal.Trim().ToLower().StartsWith("l") Then
                        genderInt = 1
                    ElseIf genderVal.Trim().ToLower().StartsWith("p") Then
                        genderInt = 2
                    End If
                End If

                ' Simpan penyakit: 1 untuk Ya, 0 untuk Tidak
                Dim penyakitInt As Integer = 0
                If Not String.IsNullOrEmpty(penyakitVal) Then
                    If penyakitVal.Trim().ToLower().StartsWith("y") Then
                        penyakitInt = 1
                    ElseIf penyakitVal.Trim().ToLower().StartsWith("t") Then
                        penyakitInt = 0
                    End If
                End If

                ' Tambahkan jawaban khusus ke dictionary jika ada (21 untuk gender, 22 untuk penyakit)
                If genderInt <> 0 Then
                    jawabanMahasiswa(21) = genderInt
                End If
                ' Untuk penyakit, tambahkan selalu, meski nilai 0 atau 1
                If Not jawabanMahasiswa.ContainsKey(22) Then
                    jawabanMahasiswa(22) = penyakitInt
                Else
                    jawabanMahasiswa(22) = penyakitInt
                End If

                ' Detail penyakit akan disimpan melalui hdnDetailPenyakit dalam SimpanJawabanKeDatabase
                System.Diagnostics.Debug.WriteLine("Disease answer processed - penyakitInt: " & penyakitInt & ", detailPenyakitVal: " & detailPenyakitVal)

            Catch ex As Exception
                System.Diagnostics.Debug.WriteLine("Error processing additional answers: " & ex.Message)
            End Try

            ' Save answers to database and get recommendations
            Dim daftarRekomendasi As List(Of RekomendasiUkm)
            
            Try
                ' Simpan jawaban
                SimpanJawabanKeDatabase(jawabanMahasiswa)

                ' Gunakan logika sederhana berbasis mapping untuk menghitung rekomendasi
                daftarRekomendasi = GenerateSimpleRecommendations(jawabanMahasiswa)

                ' Jika rekomendasi kosong (misalnya mapping belum lengkap), gunakan fallback algoritma weighted
                If daftarRekomendasi Is Nothing OrElse daftarRekomendasi.Count = 0 Then
                    daftarRekomendasi = DapatkanRekomendasiUkm(jawabanMahasiswa)
                End If
                
                ' Simpan rekomendasi ke database
                If daftarRekomendasi IsNot Nothing AndAlso daftarRekomendasi.Count > 0 Then
                    SimpanRekomendasiKeDatabase(daftarRekomendasi)
                End If

                ' Log success
                Dim recCountLog As Integer = If(daftarRekomendasi IsNot Nothing, daftarRekomendasi.Count, 0)
                System.Diagnostics.Debug.WriteLine(String.Format("Successfully saved {0} jawabanMahasiswa and {1} daftarRekomendasi to database", jawabanMahasiswa.Count, recCountLog))

                ' ========================================================================
                ' Setelah rekomendasi berhasil disimpan, buat daftar HTML untuk tab
                ' pemilihan UKM dan simpan ke hidden field.  Ini memungkinkan daftar
                ' rekomendasi dan UKM lainnya ditampilkan ketika halaman di‑refresh
                ' setelah proses kuesioner selesai.  Kami membangun dua daftar
                ' terpisah: satu untuk UKM yang direkomendasikan dan satu untuk
                ' UKM lainnya.  Setiap item dibungkus dalam elemen form‑check
                ' sehingga sesuai dengan gaya Bootstrap dan memanfaatkan checkbox
                ' untuk pemilihan UKM oleh pengguna.
                Try
                    Dim recommendedHtml As New StringBuilder()
                    Dim otherHtml As New StringBuilder()
                    Dim allUkmDict As Dictionary(Of String, Integer()) = GetUkmData()
                    Dim recommendedNames As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase)
                    ' Batasi jumlah rekomendasi yang digunakan untuk daftar checkbox maksimal 5
                    If daftarRekomendasi IsNot Nothing Then
                        ' Ambil lima teratas berdasarkan urutan aslinya
                        Dim topRecs As IEnumerable(Of RekomendasiUkm) = daftarRekomendasi.Take(5)
                        For Each rec As RekomendasiUkm In topRecs
                            If rec IsNot Nothing AndAlso Not String.IsNullOrEmpty(rec.Nama) Then
                                recommendedNames.Add(rec.Nama)
                            End If
                        Next
                    End If
                    ' Iterate all UKMs and build HTML elements
                    For Each ukmName As String In allUkmDict.Keys
                        Dim sanitizedId As String = Regex.Replace(ukmName, "[^A-Za-z0-9]", "")
                        ' Build input and label HTML with improved styling
                        ' Add custom styling for better visibility and user interaction
                        ' Tambahkan atribut name="chkUkm[]" supaya semua pilihan checkbox dikirim sebagai array.
                        ' Ganti value ke nama UKM agar yang dikirim sesuai dengan nm_ukm dari database.
                        ' Encode tanda petik tunggal dalam nama UKM untuk mencegah memutus atribut HTML.
                        Dim inputHtml As String = "<input class='form-check-input ukm-checkbox' type='checkbox' id='ukm_" & sanitizedId & "' name='chkUkm[]' value='" & ukmName.Replace("'", "&#39;") & "' data-name='" & ukmName & "' data-id='" & sanitizedId & "' />"
                        ' Tempatkan label sebelum input agar checkbox muncul di sebelah kanan nama.
                        Dim labelHtml As String = "<label class='form-check-label me-2' for='ukm_" & sanitizedId & "'>" & ukmName & "</label>"
                        ' Gunakan flexbox untuk menempatkan label dan checkbox di kiri dan kanan agar checkbox berada di ujung kanan.
                        Dim wrapperStart As String = "<div class='form-check mb-2 ukm-option p-2 rounded d-flex align-items-center justify-content-start' style='border: 1px solid #dee2e6; transition: all 0.2s ease;'>"
                        Dim wrapperEnd As String = "</div>"
                        If recommendedNames.Contains(ukmName) Then
                            recommendedHtml.AppendLine(wrapperStart & labelHtml & inputHtml & wrapperEnd)
                        Else
                            otherHtml.AppendLine(wrapperStart & labelHtml & inputHtml & wrapperEnd)
                        End If
                    Next
                    ' Tampilkan daftar rekomendasi dan UKM lainnya pada kontainer server-side
                    If litRecommendedUkmList IsNot Nothing Then
                        litRecommendedUkmList.Text = recommendedHtml.ToString()
                    End If
                    If litOtherUkmList IsNot Nothing Then
                        litOtherUkmList.Text = otherHtml.ToString()
                    End If
                    ' Tandai bahwa pemilihan UKM harus ditampilkan setelah postback
                    If hdnShowUkmSection IsNot Nothing Then
                        hdnShowUkmSection.Value = "true"
                    End If
                Catch ex2 As Exception
                    ' Jika terjadi kesalahan, catat ke debug log tetapi jangan hentikan eksekusi
                    System.Diagnostics.Debug.WriteLine("Error building UKM lists: " & ex2.Message)
                End Try
                
            Catch ex As Exception
                ' Log the error
                System.Diagnostics.Debug.WriteLine(String.Format("Error saving jawabanMahasiswa: {0}", ex.Message))
                System.Diagnostics.Debug.WriteLine(String.Format("Stack Trace: {0}", ex.StackTrace))
                
                ' Show user-friendly error message
                litPesan.Text = "<div class='alert alert-danger'><i class='fas fa-exclamation-circle me-2'></i>Terjadi kesalahan saat menyimpan jawaban. Silakan coba lagi nanti atau hubungi administrator.</div>"
                Return
            End Try
            
            ' Catat rekomendasi untuk keperluan debugging
            System.Diagnostics.Debug.WriteLine("=== DEBUG: Memproses rekomendasi ===")
            System.Diagnostics.Debug.WriteLine("Jumlah jawaban: " & jawabanMahasiswa.Count)
            
            ' Log all answers for verification
            System.Diagnostics.Debug.WriteLine("\nAnswers received:")
            For Each answer In jawabanMahasiswa
                System.Diagnostics.Debug.WriteLine("Q" & answer.Key & ": " & answer.Value)
            Next
            
            ' Log recommendations count and details
            Dim recCount = If(daftarRekomendasi IsNot Nothing, daftarRekomendasi.Count, 0)
            System.Diagnostics.Debug.WriteLine("\nGenerated " & recCount & " daftarRekomendasi")
            
            If recCount > 0 Then
                System.Diagnostics.Debug.WriteLine("\nDetail Rekomendasi:")
                For i As Integer = 0 To recCount - 1
                    System.Diagnostics.Debug.WriteLine((i + 1).ToString() & ". " & daftarRekomendasi(i).Nama & ": " & daftarRekomendasi(i).Skor & "%")
                Next
            End If
            
            System.Diagnostics.Debug.WriteLine("=== END DEBUG ===")
            
            ' Generate HTML for recommendations
            Dim htmlBuilder As New StringBuilder()
            
            ' Removed debug information for cleaner UI
            
            ' Removed the large thank you message so that only the recommendation list appears.
            
            htmlBuilder.AppendLine("<div class='card shadow mb-4 border-0'>")
            htmlBuilder.AppendLine("    <div class='card-header py-3 bg-primary text-white rounded-top'>")
            htmlBuilder.AppendLine("        <h5 class='m-0 font-weight-bold'><i class='fas fa-trophy me-2'></i>Rekomendasi UKM untuk Anda</h5>")
            htmlBuilder.AppendLine("    </div>")
            htmlBuilder.AppendLine("    <div class='card-body p-0'>")
            
            If daftarRekomendasi IsNot Nothing AndAlso daftarRekomendasi.Count > 0 Then
                htmlBuilder.AppendLine("<div class='row'>")
                htmlBuilder.AppendLine("    <div class='col-12'>")
                htmlBuilder.AppendLine("        <div class='card shadow-sm mb-4'>")
                htmlBuilder.AppendLine("            <div class='card-body p-0'>")
                htmlBuilder.AppendLine("                <div class='list-group list-group-flush'>")
                
                ' Tambahkan setiap rekomendasi sebagai card (termasuk UKM dengan skor sama)
                ' Hitung skor maksimum untuk menghitung persentase relatif di luar loop
                Dim maxScoreRec As Integer = If(daftarRekomendasi.Count > 0, daftarRekomendasi(0).Skor, 1)
                For i As Integer = 0 To daftarRekomendasi.Count - 1
                    Dim rekomendasi = daftarRekomendasi(i)
                    Dim peringkat = i + 1
                    Dim kelasMedali = If(peringkat = 1, "text-warning", If(peringkat = 2, "text-secondary", If(peringkat = 3, "text-danger", "text-muted")))
                    ' Hitung persentase untuk progress bar berdasarkan skor relatif terhadap skor tertinggi
                    Dim percentage As Integer = Math.Min(100, Math.Max(10, CInt(Math.Round((rekomendasi.Skor / maxScoreRec) * 100))))

                    ' Bangun markup: per kartu berisi ranking, detail dan checkbox di kanan
                    htmlBuilder.AppendLine("                    <div class='list-group-item p-3'>")
                    htmlBuilder.AppendLine("                        <div class='d-flex align-items-start justify-content-start'>")
                    ' Bagian kiri: ranking dan detail
                    htmlBuilder.AppendLine("                            <div class='d-flex align-items-start'>")
                    htmlBuilder.AppendLine("                                <div class='d-flex align-items-center justify-content-center me-3' style='width: 50px; height: 50px; background-color: #f8f9fa; border-radius: 50%;'>")
                    htmlBuilder.AppendLine("                                    <span class='h4 mb-0 " & kelasMedali & "'>" & peringkat & "</span>")
                    htmlBuilder.AppendLine("                                </div>")
                    htmlBuilder.AppendLine("                                <div>")
                    htmlBuilder.AppendLine("                                    <h5 class='mb-1'>" & rekomendasi.Nama & "</h5>")
                    htmlBuilder.AppendLine("                                    <p class='text-muted small mb-2'>" & rekomendasi.Deskripsi & "</p>")
                    htmlBuilder.AppendLine("                                    <div class='progress' style='height: 8px;'>")
                    htmlBuilder.AppendLine("                                        <div class='progress-bar bg-gradient-primary" & If(peringkat = 1, " progress-bar-striped progress-bar-animated " & kelasMedali, "") & "' role='progressbar' style='width: " & percentage & "%' aria-valuenow='" & percentage & "' aria-valuemin='0' aria-valuemax='100'></div>")
                    htmlBuilder.AppendLine("                                    </div>")
                    htmlBuilder.AppendLine("                                    <div class='d-flex justify-content-start mt-1'>")
                    htmlBuilder.AppendLine("                                        <small class='text-muted'>Persentase</small>")
                    htmlBuilder.AppendLine("                                        <small class='fw-bold'>" & rekomendasi.Skor & "%</small>")
                    htmlBuilder.AppendLine("                                    </div>")
                    htmlBuilder.AppendLine("                                </div>")
                    htmlBuilder.AppendLine("                            </div>")
                    ' Bagian kanan: checkbox di ujung kanan dengan styling yang lebih baik
                    htmlBuilder.AppendLine("                            <div class='align-self-center ms-auto'>")
                    htmlBuilder.AppendLine("                                <div class='form-check'>")
                    htmlBuilder.AppendLine("                                    <input type='checkbox' class='form-check-input ukm-checkbox' name='chkUkm[]' value='" & rekomendasi.Nama.Replace("'", "&#39;") & "' id='rec_" & i.ToString() & "' style='width: 20px; height: 20px;' />")
                    htmlBuilder.AppendLine("                                    <label class='form-check-label visually-hidden' for='rec_" & i.ToString() & "'>Pilih " & rekomendasi.Nama & "</label>")
                    htmlBuilder.AppendLine("                                </div>")
                    htmlBuilder.AppendLine("                            </div>")
                    htmlBuilder.AppendLine("                        </div>")
                    htmlBuilder.AppendLine("                    </div>")
                Next

                ' Tutup list-group container
                htmlBuilder.AppendLine("                </div>")
                htmlBuilder.AppendLine("            </div>")
                htmlBuilder.AppendLine("        </div>")
                
                ' Add button to show non-recommended UKMs
                htmlBuilder.AppendLine("        <div class='p-3 bg-light border-top'>")
                htmlBuilder.AppendLine("            <div class='d-flex justify-content-between align-items-start'>")
                htmlBuilder.AppendLine("                <div class='d-flex'>")
                htmlBuilder.AppendLine("                    <div class='flex-shrink-0 me-2'><i class='fas fa-info-circle text-primary'></i></div>")
                htmlBuilder.AppendLine("                    <div class='small'>")
                htmlBuilder.AppendLine("                        <strong>Keterangan:</strong> Daftar UKM diurutkan berdasarkan skor tertinggi. ")
                htmlBuilder.AppendLine("                        Jika ada lebih dari lima UKM dengan skor yang sama, semua UKM dengan skor tersebut ditampilkan. ")
                htmlBuilder.AppendLine("                        Skor merupakan persentase kecocokan (0-100%) yang dihitung dari jawaban Anda dan bobot relevansi UKM untuk setiap pertanyaan. ")
                htmlBuilder.AppendLine("                        <span class='d-block mt-1 fw-semibold'>Anda bebas memilih UKM manapun yang paling menarik minat Anda!</span>")
                htmlBuilder.AppendLine("                    </div>")
                htmlBuilder.AppendLine("                </div>")
                htmlBuilder.AppendLine("                <div class='ms-3 d-flex gap-2'>")
                htmlBuilder.AppendLine("                    <button type='button' class='btn btn-outline-primary btn-sm' id='btnShowOtherUkms' onclick='toggleOtherUkms()'>")
                htmlBuilder.AppendLine("                        <i class='fas fa-list me-1'></i>Lihat UKM Lainnya")
                htmlBuilder.AppendLine("                    </button>")
                htmlBuilder.AppendLine("                    <button type='button' class='btn btn-success btn-sm' id='btnSubmitUkmSelection' onclick='submitUkmSelection()'>")
                htmlBuilder.AppendLine("                        <i class='fas fa-check me-1'></i>Simpan Pilihan")
                htmlBuilder.AppendLine("                    </button>")
                htmlBuilder.AppendLine("                </div>")
                htmlBuilder.AppendLine("            </div>")
                htmlBuilder.AppendLine("        </div>")
            Else
                htmlBuilder.AppendLine("        <div class='p-4 text-center'>")
                htmlBuilder.AppendLine("            <div class='mb-3'><i class='fas fa-search fa-3x text-muted mb-3'></i></div>")
                htmlBuilder.AppendLine("            <h5 class='text-muted mb-3'>Tidak ada rekomendasi yang tersedia</h5>")
                htmlBuilder.AppendLine("            <p class='text-muted'>Maaf, kami tidak dapat memberikan rekomendasi berdasarkan jawaban Anda. Silakan coba lagi atau hubungi admin.</p>")
                htmlBuilder.AppendLine("        </div>")
            End If
            
            htmlBuilder.AppendLine("    </div>")
            htmlBuilder.AppendLine("</div>")
            
            ' Add section for non-recommended UKMs (initially hidden)
            htmlBuilder.AppendLine("<div class='card shadow mb-4 border-0' id='otherUkmsCard' style='display: none;'>")
            htmlBuilder.AppendLine("    <div class='card-header py-3 bg-secondary text-white rounded-top'>")
            htmlBuilder.AppendLine("        <h5 class='m-0 font-weight-bold'><i class='fas fa-list me-2'></i>UKM Lainnya</h5>")
            htmlBuilder.AppendLine("    </div>")
            htmlBuilder.AppendLine("    <div class='card-body p-0'>")
            htmlBuilder.AppendLine("        <div class='p-3'>")
            htmlBuilder.AppendLine("            <p class='text-muted mb-3'>Berikut adalah daftar UKM lainnya yang tidak masuk dalam rekomendasi utama berdasarkan jawaban Anda. Anda tetap dapat memilih UKM ini jika sesuai dengan minat Anda.</p>")
            htmlBuilder.AppendLine("            <div id='otherUkmsList'>")
            
            ' Generate list of non-recommended UKMs
            If daftarRekomendasi IsNot Nothing AndAlso daftarRekomendasi.Count > 0 Then
                Dim dataUkm = GetUkmData()
                Dim deskripsiUkm = GetUkmDescriptions()
                Dim recommendedNames As New HashSet(Of String)(StringComparer.OrdinalIgnoreCase)
                
                ' Get names of recommended UKMs
                For Each rec In daftarRekomendasi
                    recommendedNames.Add(rec.Nama)
                Next
                
                ' Generate dropdown/list for non-recommended UKMs
                htmlBuilder.AppendLine("                <div class='row'>")
                Dim otherUkmCount As Integer = 0
                For Each ukm In dataUkm.Keys
                    If Not recommendedNames.Contains(ukm) Then
                        otherUkmCount += 1
                        Dim desc As String = If(deskripsiUkm.ContainsKey(ukm), deskripsiUkm(ukm), "Deskripsi tidak tersedia")
                        
                        htmlBuilder.AppendLine("                    <div class='col-md-6 mb-3'>")
                        htmlBuilder.AppendLine("                        <div class='card h-100 border-light'>")
                        htmlBuilder.AppendLine("                            <div class='card-body p-3'>")
                        htmlBuilder.AppendLine("                                <h6 class='card-title mb-2'>" & ukm & "</h6>")
                        htmlBuilder.AppendLine("                                <p class='card-text small text-muted mb-2'>" & desc & "</p>")
                        htmlBuilder.AppendLine("                                <div class='form-check d-flex align-items-center mt-2'>")
                        htmlBuilder.AppendLine("                                    <input class='form-check-input ukm-checkbox me-2' type='checkbox' name='chkUkm[]' value='" & ukm.Replace("'", "&#39;") & "' id='other_" & ukm.GetHashCode().ToString().Replace("-", "N") & "' style='width: 18px; height: 18px; margin-top: 0; margin-left: 0; position: relative;' />")
                        htmlBuilder.AppendLine("                                    <label class='form-check-label small mb-0' for='other_" & ukm.GetHashCode().ToString().Replace("-", "N") & "'>Pilih UKM ini</label>")
                        htmlBuilder.AppendLine("                                </div>")
                        htmlBuilder.AppendLine("                            </div>")
                        htmlBuilder.AppendLine("                        </div>")
                        htmlBuilder.AppendLine("                    </div>")
                    End If
                Next
                htmlBuilder.AppendLine("                </div>")
                
                If otherUkmCount = 0 Then
                    htmlBuilder.AppendLine("                <div class='text-center text-muted'>")
                    htmlBuilder.AppendLine("                    <p>Semua UKM sudah masuk dalam rekomendasi.</p>")
                    htmlBuilder.AppendLine("                </div>")
                End If
            End If
            
            htmlBuilder.AppendLine("            </div>")
            htmlBuilder.AppendLine("        </div>")
            htmlBuilder.AppendLine("    </div>")
            htmlBuilder.AppendLine("</div>")
            
            ' Previously the recommendation card included a footer with action buttons to return
            ' to the homepage or reload the questionnaire.  These buttons created an unwanted
            ' footer area at the bottom of the results.  The footer has been removed to keep
            ' the results page clean and focused on the recommendation content.  All
            ' navigation is now handled through the tab interface at the top of the form.
            
            ' Data rekomendasi sudah disimpan sebelumnya saat memproses jawaban di atas.
            ' Pemanggilan kedua ini dihapus untuk mencegah penghapusan dan penulisan ulang data secara berulang.
            
            ' Always show the recommendation list in litPesan.
            litPesan.Text = htmlBuilder.ToString()
            
        Catch ex As Exception
            litPesan.Text = String.Format("<div class='alert alert-danger'>Terjadi kesalahan: {0}</div>", ex.Message)
        End Try
    End Sub
    
    Protected Sub btnSubmit_Click(sender As Object, e As EventArgs)
        ' Disease information will be saved as part of the main answer processing
        ' Process the answers which will handle disease information automatically
        btnProcessAnswers_Click(sender, e)
    End Sub
    
    ' NOTE: SaveDiseaseInformation method removed - disease information is now saved 
    ' directly in SimpanJawabanKeDatabase method as part of the main answer saving process
    
    Protected Sub btnKembali_Click(ByVal sender As Object, ByVal e As EventArgs)
        ' Reset form dan muat ulang pertanyaan
        LoadPertanyaan()
    End Sub

    '----------------------------------------------------------------------------------
    ' Handler for submitting biodata.  This method collects the student's Line ID,
    ' Instagram username, WhatsApp number and the list of selected UKM codes
    ' (comma‑separated) and inserts them into the tkuesioner_mhs table.  The NIM is
    ' derived using the same session lookup logic used when processing answers.  If
    ' the insertion succeeds, a success message is displayed; otherwise an error
    ' message is shown.  This method does not update the existing recommendation
    ' records but is solely responsible for capturing the biodata and selected UKMs.
    Protected Sub btnSubmitBiodata_Click(sender As Object, e As EventArgs)
        Try
            litPesan.Text = ""
            
            ' Ambil NIM dari session seperti fungsi lain yang sudah bekerja
            Dim nim As String = ""
            If Session("idlintar") IsNot Nothing Then
                nim = Session("idlintar").ToString().Trim()
            ElseIf Session("UserId") IsNot Nothing Then
                nim = Session("UserId").ToString().Trim()
            Else
                nim = "TEST123" ' Fallback untuk testing
            End If

            ' Ambil data dari form
            Dim idLine As String = If(txtIdLine IsNot Nothing, txtIdLine.Text.Trim(), "")
            Dim instagram As String = If(txtInstagram IsNot Nothing, txtInstagram.Text.Trim(), "")
            Dim wa As String = If(txtWhatsapp IsNot Nothing, txtWhatsapp.Text.Trim(), "")
            Dim minat As String = If(ddlMinat IsNot Nothing, ddlMinat.SelectedValue, "")
            Dim selectedUkms As String = If(hdnSelectedUkms IsNot Nothing, hdnSelectedUkms.Value, "")
            
            ' Konversi nama UKM ke kode UKM
            Dim selectedUkmCodes As String = ""
            If Not String.IsNullOrEmpty(selectedUkms) Then
                Dim ukmNames() As String = selectedUkms.Split(","c)
                Dim ukmCodes As New List(Of String)()
                For Each ukmName As String In ukmNames
                    Dim kodeUkm As Integer = AmbilKodeUkm(ukmName.Trim())
                    If kodeUkm > 0 Then
                        ukmCodes.Add(kodeUkm.ToString())
                    End If
                Next
                selectedUkmCodes = String.Join(",", ukmCodes)
            End If

            ' Simpan ke database menggunakan pola yang sama dengan fungsi lain
            Using conn As New OleDbConnection(connstringlintar)
                conn.Open()
                
                ' Tentukan nama tabel berdasarkan provider database
                Dim tableName As String
                If connstringlintar.ToLower().Contains("sql") Then
                    tableName = "admawa.dbo.tkuesioner_mhs"
                Else
                    tableName = "tkuesioner_mhs"
                End If
                
                ' Coba update dulu
                Dim sqlUpdate As String = "UPDATE " & tableName & " SET idline = ?, instagram = ?, nowa = ?, minat = ?, listminat = ? WHERE nim = ?"
                Using cmdUpdate As New OleDbCommand(sqlUpdate, conn)
                    cmdUpdate.Parameters.AddWithValue("p1", idLine)
                    cmdUpdate.Parameters.AddWithValue("p2", instagram)
                    cmdUpdate.Parameters.AddWithValue("p3", wa)
                    cmdUpdate.Parameters.AddWithValue("p4", minat)
                    cmdUpdate.Parameters.AddWithValue("p5", selectedUkmCodes)
                    cmdUpdate.Parameters.AddWithValue("p6", nim)
                    
                    Dim rowsAffected As Integer = cmdUpdate.ExecuteNonQuery()
                    
                    ' Jika tidak ada yang terupdate, lakukan insert
                    If rowsAffected = 0 Then
                        Dim sqlInsert As String = "INSERT INTO " & tableName & " (nim, idline, instagram, nowa, minat, listminat) VALUES (?, ?, ?, ?, ?, ?)"
                        Using cmdInsert As New OleDbCommand(sqlInsert, conn)
                            cmdInsert.Parameters.AddWithValue("p1", nim)
                            cmdInsert.Parameters.AddWithValue("p2", idLine)
                            cmdInsert.Parameters.AddWithValue("p3", instagram)
                            cmdInsert.Parameters.AddWithValue("p4", wa)
                            cmdInsert.Parameters.AddWithValue("p5", minat)
                            cmdInsert.Parameters.AddWithValue("p6", selectedUkmCodes)
                            cmdInsert.ExecuteNonQuery()
                        End Using
                    End If
                End Using
            End Using
            
            ' Tampilkan popup sukses dan redirect ke halaman awal sistem rekomendasi
            Session("BiodataSaved") = "true"
            Dim script As String = "alert('Biodata berhasil disimpan!'); window.location.href = window.location.pathname;"
            Page.ClientScript.RegisterStartupScript(Me.GetType(), "BiodataSuccess", script, True)
            
        Catch ex As Exception
            litPesan.Text = "<div class='alert alert-danger'><i class='fas fa-exclamation-circle me-2'></i>Terjadi kesalahan: " & ex.Message & "</div>"
        End Try
    End Sub
    
    Private Function ProsesRekomendasi(ByVal jawaban As Dictionary(Of Integer, String)) As String
        ' Logika untuk menentukan rekomendasi UKM berdasarkan jawaban
        ' Ini adalah contoh sederhana, Anda perlu menyesuaikan dengan logika bisnis yang sesuai
        
        ' Contoh: Hitung total skor untuk setiap UKM
        Dim skorUKM As New Dictionary(Of String, Integer)()
        
        For Each j As KeyValuePair(Of Integer, String) In jawaban
            ' Dapatkan bobot jawaban dari database
            Dim bobot As Integer = 0
            
            Select Case j.Value
                Case "Sangat Setuju"
                    bobot = 5
                Case "Setuju"
                    bobot = 4
                Case "Ragu-Ragu"
                    bobot = 3
                Case "Tidak Setuju"
                    bobot = 2
                Case "Sangat Tidak Setuju"
                    bobot = 1
            End Select
            
            ' Simpan skor di dictionary
            If skorUKM.ContainsKey("UKM1") Then
                skorUKM("UKM1") += bobot
            Else
                skorUKM.Add("UKM1", bobot)
            End If
            
            If skorUKM.ContainsKey("UKM2") Then
                skorUKM("UKM2") += bobot
            Else
                skorUKM.Add("UKM2", bobot)
            End If
            
            If skorUKM.ContainsKey("UKM3") Then
                skorUKM("UKM3") += bobot
            Else
                skorUKM.Add("UKM3", bobot)
            End If
        Next
        
        ' Dapatkan UKM dengan skor tertinggi
        If skorUKM.Count > 0 Then
            Dim rekomendasiTerbaik As KeyValuePair(Of String, Integer) = skorUKM.OrderByDescending(Function(x) x.Value).First()
            
            Return "UKM " & rekomendasiTerbaik.Key
        End If
        
        Return "Tidak ada rekomendasi yang sesuai. Silakan coba lagi atau hubungi admin."
    End Function

    '-----------------------------------------------------------------
    ' Handler for the new "Simpan Pilihan" button in the UKM selection section.
    ' This method reads the selected UKM names from the posted form, computes
    ' the academic year (thn_akdk) from the NIM, and saves or updates the
    ' tkuesioner_mhs table.  The selected UKM names are joined with commas
    ' and stored in the listminat column.  If a record for the current NIM
    ' exists, the row is updated; otherwise a new row is inserted.
    Protected Sub btnSubmitPilihanUkm_Click(sender As Object, e As EventArgs)
        Try
            ' Bersihkan pesan sebelumnya
            litPesan.Text = ""

            ' Ambil NIM dari session.  Periksa berbagai kemungkinan key untuk fleksibilitas
            Dim nim As String = ""
            If Session IsNot Nothing Then
                If Session("NIM") IsNot Nothing Then
                    nim = Session("NIM").ToString()
                ElseIf Session("nim") IsNot Nothing Then
                    nim = Session("nim").ToString()
                ElseIf Session("username") IsNot Nothing Then
                    nim = Session("username").ToString()
                ElseIf Session("Username") IsNot Nothing Then
                    nim = Session("Username").ToString()
                ElseIf Session("user_id") IsNot Nothing Then
                    nim = Session("user_id").ToString()
                ElseIf Session("UserId") IsNot Nothing Then
                    nim = Session("UserId").ToString()
                ElseIf Session("student_id") IsNot Nothing Then
                    nim = Session("student_id").ToString()
                ElseIf Session("StudentId") IsNot Nothing Then
                    nim = Session("StudentId").ToString()
                End If
            End If

            ' Jika tidak ada NIM valid, gunakan nilai sementara untuk pengujian
            If String.IsNullOrEmpty(nim) Then
                nim = "TEST123"
            End If

            ' Baca pilihan UKM dari hidden field atau form
            Dim selectedUkms As String = ""
            If Not String.IsNullOrEmpty(hdnSelectedUkms.Value) Then
                selectedUkms = hdnSelectedUkms.Value
            Else
                ' Fallback: baca dari checkbox form
                Dim selectedUkmsArray As String() = Request.Form.GetValues("chkUkm[]")
                If selectedUkmsArray IsNot Nothing AndAlso selectedUkmsArray.Length > 0 Then
                    selectedUkms = String.Join(",", selectedUkmsArray)
                End If
            End If
            
            ' Validasi pilihan UKM
            If String.IsNullOrEmpty(selectedUkms) Then
                litPesan.Text = "<div class='alert alert-warning'><i class='fas fa-exclamation-triangle me-2'></i>Silakan pilih minimal satu UKM.</div>"
                Return
            End If

            ' Hitung nilai thn_akdk dari dua digit ke-4 dan ke-5 NIM.  Contoh: nim 825220078 -> "22" -> 20221
            Dim thnAkdk As String = ""
            Try
                If nim.Length >= 5 Then
                    Dim yearDigits As String = nim.Substring(3, 2)
                    ' Hanya lanjut jika dua digit ini numerik
                    Dim yearNum As Integer
                    If Integer.TryParse(yearDigits, yearNum) Then
                        thnAkdk = "20" & yearDigits & "1"
                    End If
                End If
            Catch exParse As Exception
                ' Jika parsing gagal, biarkan thnAkdk tetap kosong
            End Try

            ' Simpan atau perbarui data ke database
            Try
                Using conn As New OleDbConnection(connstringlintar)
                    conn.Open()
                    ' Determine table name based on database provider
                    Dim tableName As String
                    If connstringlintar.ToLower().Contains("sql") Then
                        tableName = "admawa.dbo.tkuesioner_mhs"
                    Else
                        tableName = "tkuesioner_mhs"
                    End If
                    Dim sqlUpdate As String = "UPDATE " & tableName & " SET listminat = ?, thn_akdk = ? WHERE nim = ?"
                    Dim rowsAffected As Integer = 0
                    ' Jalankan update untuk mencoba memperbarui baris yang sudah ada
                    Using cmd As New OleDbCommand(sqlUpdate, conn)
                        ' OleDbCommand requires parameters in the exact order they appear in the SQL
                        cmd.Parameters.AddWithValue("listminat", selectedUkms)
                        cmd.Parameters.AddWithValue("thn_akdk", thnAkdk)
                        cmd.Parameters.AddWithValue("nim", nim)
                        rowsAffected = cmd.ExecuteNonQuery()
                    End Using
                    ' Jika tidak ada baris terupdate, lakukan insert
                    If rowsAffected = 0 Then
                        Dim sqlInsert As String = "INSERT INTO " & tableName & " (nim, listminat, thn_akdk) VALUES (?, ?, ?)"
                        Using cmdIns As New OleDbCommand(sqlInsert, conn)
                            ' OleDbCommand requires parameters in the exact order they appear in the SQL
                            cmdIns.Parameters.AddWithValue("nim", nim)
                            cmdIns.Parameters.AddWithValue("listminat", selectedUkms)
                            cmdIns.Parameters.AddWithValue("thn_akdk", thnAkdk)
                            cmdIns.ExecuteNonQuery()
                        End Using
                    End If
                End Using
                
                ' Show success alert and redirect to biodata tab
                Page.ClientScript.RegisterStartupScript(Me.GetType(), "ShowUkmSuccessAlert", 
                    "alert('✅ Pilihan UKM berhasil disimpan!'); " & _
                    "console.log('Switching to biodata tab...'); " & _
                    "setTimeout(function() { " & _
                    "var ukmTab = document.getElementById('ukm-tab'); " & _
                    "var biodataTab = document.getElementById('biodata-tab'); " & _
                    "var ukmSection = document.getElementById('ukmSection'); " & _
                    "var biodataSection = document.getElementById('biodataSection'); " & _
                    "console.log('Elements found:'); " & _
                    "console.log('ukmTab:', ukmTab); " & _
                    "console.log('biodataTab:', biodataTab); " & _
                    "console.log('ukmSection:', ukmSection); " & _
                    "console.log('biodataSection:', biodataSection); " & _
                    "if (!biodataSection) { " & _
                    "console.error('biodataSection not found! Checking all elements with biodata...'); " & _
                    "var allBiodata = document.querySelectorAll('[id*=""biodata""]'); " & _
                    "console.log('All biodata elements:', allBiodata); " & _
                    "} " & _
                    "if (ukmTab) ukmTab.classList.remove('active'); " & _
                    "if (biodataTab) { biodataTab.classList.add('active'); biodataTab.disabled = false; } " & _
                    "if (ukmSection) ukmSection.style.display = 'none'; " & _
                    "var biodataPane = document.getElementById('biodata-tab-pane'); " & _
                    "if (biodataPane) { " & _
                    "biodataPane.style.display = 'block'; " & _
                    "biodataPane.style.visibility = 'visible'; " & _
                    "biodataPane.classList.remove('fade'); " & _
                    "biodataPane.classList.add('show', 'active'); " & _
                    "console.log('Biodata pane classes after change:', biodataPane.className); " & _
                    "console.log('Biodata pane display after change:', biodataPane.style.display); " & _
                    "} else { " & _
                    "console.error('biodata-tab-pane element not found!'); " & _
                    "} " & _
                    "window.scrollTo(0, 0); " & _
                    "}, 500);", True)
                    
            Catch exSave As Exception
                ' Tampilkan pesan kesalahan jika gagal menyimpan
                litPesan.Text = "<div class='alert alert-danger'><i class='fas fa-exclamation-circle me-2'></i>Terjadi kesalahan saat menyimpan pilihan UKM: " & exSave.Message & "</div>"
            End Try
        Catch ex As Exception
            ' Tangani kesalahan tak terduga
            litPesan.Text = "<div class='alert alert-danger'><i class='fas fa-exclamation-circle me-2'></i>Terjadi kesalahan tak terduga saat menyimpan pilihan UKM.</div>"
        End Try
    End Sub

</script>
</script>
<script type="text/javascript">
  $(document).ready(function() {
    // Jika hidden field menunjukkan UKM section harus ditampilkan, tampilkan tab Pemilihan UKM
    var showUkm = $('#<%= hdnShowUkmSection.ClientID %>').val();
    if (showUkm && (showUkm.toLowerCase() === 'true')) {
        // Sembunyikan bagian tes dan kartu awal
        $('#test-tab-pane').hide();
        $('#startCard').hide();
        // Tampilkan pemilihan UKM dan sembunyikan biodata
        $('#ukmSection').show();
        $('#biodataSection').hide();
        $('#biodata-tab-pane').hide();
        // Perbarui navigasi tab
        $('#ukm-tab').prop('disabled', false);
        $('#biodata-tab').prop('disabled', false);
        $('#test-tab').removeClass('active');
        $('#ukm-tab').addClass('active');
        $('#biodata-tab').removeClass('active');
        // Daftar UKM rekomendasi dan lainnya telah dirender di server; cukup pasang handler.
        // Pasang handler untuk update daftar pilihan UKM ke hidden field
        $(document).off('change.ukmInit').on('change.ukmInit', function updateSelectedUkms() {
            var selected = [];
            $('.ukm-checkbox:checked').each(function() {
                var ukmName = $(this).val() || $(this).data('name');
                if (ukmName) {
                    selected.push(ukmName);
                }
            });
            selectedUkms = selected;
            $('#<%= hdnSelectedUkms.ClientID %>').val(selected.join(','));
        });
        
        // Make updateSelectedUkms globally available
        window.updateSelectedUkms = updateSelectedUkms;
    }
  });
</script>
    <!-- Script untuk menampilkan tab pemilihan UKM setelah kuesioner selesai -->
    <script type="text/javascript">
        $(document).ready(function() {
            // Periksa apakah server menandai untuk menampilkan tab pemilihan UKM
            var showUkm = $('#<%= hdnShowUkmSection.ClientID %>').val();
            if (showUkm && (showUkm.toLowerCase() === 'true')) {
                // Sembunyikan panel tes dan kartu awal
                $('#test-tab-pane').hide();
                $('#startCard').hide();
                // Tampilkan pemilihan UKM dan sembunyikan biodata
                $('#ukmSection').show();
                $('#biodataSection').hide();
                // Perbarui status tab navigasi
                $('#ukm-tab').prop('disabled', false);
                $('#biodata-tab').prop('disabled', false);
                $('#test-tab').removeClass('active');
                $('#ukm-tab').addClass('active');
                $('#biodata-tab').removeClass('active');
                // Daftar UKM rekomendasi dan lainnya telah dirender di server; cukup pasang handler.
                $(document).off('change.ukmInit').on('change.ukmInit', '.ukm-checkbox', function() {
                    var codes = [];
                    $('.ukm-checkbox:checked').each(function() {
                        var code = $(this).val() || $(this).data('name') || $(this).data('id');
                        if (code) { codes.push(code); }
                    });
                    $('#<%= hdnSelectedUkms.ClientID %>').val(codes.join(','));
                });
            }
        });
    </script>

<!-- Add jQuery and Bootstrap 5 CSS/JS -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-1BmE4kWBq78iYhFldvKuhfTAU6auU8tT94WrHftjDbrCEXSU1oBoqyl2QvZ6jIW3" crossorigin="anonymous">
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js" integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p" crossorigin="anonymous"></script>

<!-- Ensure jQuery is loaded before other scripts -->
<script>
    // Check if jQuery is loaded
    if (typeof jQuery == 'undefined') {
        document.write(unescape("%3Cscript src='https://code.jquery.com/jquery-3.6.0.min.js'%3E%3C/script%3E"));
    }
    
    // Check if Bootstrap is loaded
    if (typeof bootstrap === 'undefined') {
        document.write(unescape("%3Cscript src='https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js' integrity='sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p' crossorigin='anonymous'%3E%3C/script%3E"));
    }
</script>

<!-- Back to top button -->
<button type="button" class="btn btn-primary btn-floating btn-lg rounded-circle" id="btn-back-to-top" style="position: fixed; bottom: 20px; right: 20px; display: none; z-index: 1000;">
    <i class="fas fa-arrow-up"></i>
</button>

<style>
    #btn-back-to-top {
        width: 50px;
        height: 50px;
        padding: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        transition: all 0.3s ease-in-out;
    }
    
    #btn-back-to-top:hover {
        transform: translateY(-3px);
        box-shadow: 0 5px 15px rgba(0, 0, 0, 0.3);
    }
</style>

<div class="content-wrapper p-3">
  <section class="content">
    <div class="container-fluid mt-4">
      <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="m-0" style="font-size: 1.5rem; font-weight: 600;"><strong>Rekomendasi UKM</strong></h2>
        <div style="color: #6c757d;">
          <a href="index.aspx" style="color: #6c757d; text-decoration: none;">Beranda</a> / Rekomendasi UKM
        </div>
      </div>
    </div>
  </section>
  
  <section class="content">
    <div class="container-fluid">
      <form id="form1" runat="server">
        <!-- Tab Navigation -->
        <ul class="nav nav-tabs mb-3" id="ukmTabs" role="tablist">
          <li class="nav-item" role="presentation">
            <button class="nav-link active" id="test-tab" data-bs-toggle="tab" data-bs-target="#test-tab-pane" type="button" role="tab" aria-controls="test-tab-pane" aria-selected="true">
              <i class="fas fa-clipboard-check me-2"></i>Tes Minat
            </button>
          </li>
          <li class="nav-item" role="presentation">
            <button class="nav-link" id="ukm-tab" data-bs-toggle="tab" data-bs-target="#ukm-tab-pane" type="button" role="tab" aria-controls="ukm-tab-pane" aria-selected="false" disabled>
              <i class="fas fa-list-check me-2"></i>Pemilihan UKM
            </button>
          </li>
          <li class="nav-item" role="presentation">
            <button class="nav-link" id="biodata-tab" data-bs-toggle="tab" data-bs-target="#biodata-tab-pane" type="button" role="tab" aria-controls="biodata-tab-pane" aria-selected="false" disabled>
              <i class="fas fa-user me-2"></i>Biodata
            </button>
          </li>
        </ul>
        <asp:Literal ID="litPesan" runat="server"></asp:Literal>
        
        <!-- Tab Content -->
        <div class="tab-content p-3 border border-top-0 rounded-bottom" id="ukmTabsContent">
          <!-- Tes Minat Tab -->
          <div class="tab-pane fade show active" id="test-tab-pane" role="tabpanel" aria-labelledby="test-tab" tabindex="0">
        
        <!-- Disease Information -->
        <div class="card shadow mb-4" id="diseaseSection" style="display: none;">
          <div class="card-header bg-info text-white">
            <h5 class="mb-0">Informasi Kesehatan</h5>
          </div>
          <div class="card-body">
            <div class="form-group">
              <label for="txtPenyakitBawaan">Sebutkan penyakit bawaan Anda (jika ada):</label>
              <asp:TextBox ID="txtPenyakitBawaan" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="3" placeholder="Kosongkan jika tidak ada"></asp:TextBox>
              <small class="form-text text-muted">Informasi ini akan membantu kami memberikan rekomendasi yang sesuai dengan kondisi kesehatan Anda.</small>
            </div>
            <div class="text-right mt-3">
              <button type="button" id="btnNextToResults" class="btn btn-primary">Lanjutkan ke Hasil</button>
            </div>
          </div>
        </div>

        <!-- Start Screen -->
        <div class="card shadow" id="startCard">
          <div class="card-body text-center py-4 px-5">
            <div class="mb-3">
              <img src="../../images/kuesioner.png" alt="Kuesioner Rekomendasi UKM" class="img-fluid" style="width: 60px; height: 60px; margin-bottom: 10px;">
              <h2 class="h4 text-gray-800 mb-2"><strong>Kuesioner Rekomendasi UKM</strong></h2>
              <p class="text-muted mb-3" style="font-size: 0.9em;">
                Jawab Beberapa Pertanyaan untuk Mendapatkan Rekomendasi Unit Kegiatan Mahasiswa (UKM) yang sesuai dengan minat dan Bakat Anda
              </p>
              <button type="button" class="btn btn-primary btn-lg px-5" id="btnStart">
                <i class="fas fa-play me-2"></i>Mulai Kuesioner
              </button>
            </div>
          </div>
        </div>
        
        <!-- Question Modal -->
        <div class="modal fade" id="questionModal" tabindex="-1" aria-hidden="true" data-bs-backdrop="static">
          <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow">
              <div class="modal-header border-0 pb-0">
                <h5 class="modal-title d-flex align-items-center">
                  <span>Pertanyaan</span>
                  <span class="badge bg-light text-dark ms-2">
                    <span id="questionNumber">1</span>/<span id="totalQuestions">20</span>
                  </span>
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
              </div>
              <div class="modal-body pt-0">
                <!-- Progress Bar -->
                <div class="progress mb-4" style="height: 6px;">
                  <div class="progress-bar bg-primary" role="progressbar" style="width: 5%" 
                       aria-valuenow="5" aria-valuemin="0" aria-valuemax="100"></div>
                </div>
                
                <!-- Question Text -->
                <h4 id="questionText" class="mb-4 fw-bold text-dark"></h4>
                
                <!-- Answer Options -->
                <div id="answerOptions" class="list-group list-group-flush">
                  <!-- Options will be inserted here by JavaScript -->
                </div>
              </div>
              <div class="modal-footer border-0 pt-0">
                <button type="button" class="btn btn-outline-secondary px-4" id="btnPrev" disabled>
                  <i class="fas fa-arrow-left me-2"></i>Sebelumnya
                </button>
                <div>
                  <button type="button" class="btn btn-primary px-4" id="btnNext">
                    Selanjutnya<i class="fas fa-arrow-right ms-2"></i>
                  </button>
                  <button type="button" class="btn btn-success px-4" id="btnSubmit" style="display:none;">
                    <i class="fas fa-check me-2"></i>Selesai
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!--
            NOTE: The start button ("Mulai Kuesioner") click handler is now managed within
            the main questionnaire script defined further below. The previous standalone
            initialization script has been removed to avoid duplicate event bindings and
            references to undefined functions. Removing this block prevents errors where
            the click handler referenced a `showQuestion` function that was not yet in
            scope, which caused the start button to appear non‑functional.
        -->
        
        <!-- Hidden fields to store jawabanMahasiswa and questions -->
        <asp:HiddenField ID="hdnAnswers" runat="server" />
        <asp:HiddenField ID="hdnPenyakitBawaan" runat="server" />
        <asp:HiddenField ID="hdnQuestions" runat="server" />
        <!-- Hidden fields for additional pertanyaan khusus (jenis kelamin dan penyakit) -->
        <asp:HiddenField ID="hdnGender" runat="server" />
        <asp:HiddenField ID="hdnPenyakit" runat="server" />
        <asp:HiddenField ID="hdnDetailPenyakit" runat="server" />
        <!-- Hidden field to store selected UKM codes (comma-separated) -->
        <asp:HiddenField ID="hdnSelectedUkms" runat="server" />
        <!-- Hidden fields for controlling section visibility and storing recommended UKM lists -->
        <asp:HiddenField ID="hdnShowSelesai" runat="server" Value="false" />
        <asp:HiddenField ID="hdnShowUkmSection" runat="server" Value="false" />
        <asp:Button ID="btnProcessAnswers" runat="server" 
        OnClick="btnProcessAnswers_Click" 
        Text="Process Answers"
        style="display: none;" />
        
        <!-- Panel Pertanyaan (hidden, for data binding) -->
        <asp:Panel ID="pnlPertanyaan" runat="server" style="display:none;">
          <asp:Repeater ID="rptPertanyaan" runat="server" OnItemDataBound="rptPertanyaan_ItemDataBound">
            <ItemTemplate>
              <div class="question-item" data-question-id='<%# Container.ItemIndex %>'>
                <div class="question-text"><%# Eval("pertanyaan") %></div>
                <asp:RadioButtonList ID="rblJawaban" runat="server" CssClass="form-check">
                </asp:RadioButtonList>
              </div>
            </ItemTemplate>
          </asp:Repeater>
        </asp:Panel>
        
        <!-- Panel Hasil -->
        <asp:Panel ID="pnlHasil" runat="server" Visible="false">
          <div class="card">
            <div class="card-header bg-success text-white">
              <h3 class="card-title">Hasil Rekomendasi UKM</h3>
            </div>
            <div class="card-body">
              <asp:Literal ID="litHasil" runat="server"></asp:Literal>
              <div class="text-center mt-4">
                <asp:Button ID="btnKembali" runat="server" Text="Kembali ke Awal" 
                  CssClass="btn btn-primary" OnClick="btnKembali_Click" />
              </div>
            </div>
          </div>
        </asp:Panel>

        <!--
            ================================================================================
            UKM Selection and Biodata Sections
            
            After the questionnaire is completed, the user will be presented with a list of
            recommended UKMs to choose from and a secondary list of non‑recommended UKMs.
            The selected codes will be stored in the hidden field hdnSelectedUkms as a
            comma‑separated string.  Once the user proceeds to the biodata tab, they can
            enter their Line ID, Instagram handle and WhatsApp number.  These details,
            along with the list of selected UKM codes, will be saved to the tkuesioner_mhs
            table when the form is submitted.
        -->

          </div>
          
          <!-- UKM Selection Tab -->
          <div class="tab-pane fade" id="ukm-tab-pane" role="tabpanel" aria-labelledby="ukm-tab" tabindex="0">
            <!-- Pemilihan UKM Tab Content (initially hidden; shown when the test is complete) -->
            <div id="ukmSection" style="display: none;">
              <div class="card shadow mb-4">
                <div class="card-header bg-primary text-white">
                  <h5 class="mb-0"><i class="fas fa-list-check me-2"></i>Pemilihan UKM</h5>
                </div>
                <div class="card-body">
                  <p class="text-muted">Berikut merupakan daftar UKM yang direkomendasikan berdasarkan jawaban Anda. Centang UKM yang ingin Anda pilih. Anda juga dapat memilih UKM lainnya dari daftar di bawah.</p>
                  <!-- Recommended UKMs will be rendered here -->
                  <div id="recommendedUkmList" class="mb-4">
                    <asp:Literal ID="litRecommendedUkmList" runat="server" />
                  </div>
                  <h5 class="mt-4 mb-2">UKM Lainnya</h5>
                  <!-- Non‑recommended UKMs will be rendered here -->
                  <div id="otherUkmList">
                    <asp:Literal ID="litOtherUkmList" runat="server" />
                  </div>
                  <div class="d-flex justify-content-between mt-4">
                    <button type="button" class="btn btn-secondary" id="btnBackToTest"><i class="fas fa-arrow-left me-2"></i>Kembali</button>
                    <button type="button" class="btn btn-primary" id="btnNextToBiodata">Selanjutnya<i class="fas fa-arrow-right ms-2"></i></button>
                  </div>
                  <!-- Tombol untuk menyimpan pilihan UKM. Ditempatkan di bagian bawah form agar pengguna bisa mengirimkan pilihan sebelum melanjutkan. -->
                  <div class="mt-3 text-end">
                    <asp:Button ID="btnSubmitPilihanUkm" runat="server" CssClass="btn btn-success" Text="Simpan Pilihan" OnClick="btnSubmitPilihanUkm_Click" />
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Biodata Tab -->
          <div class="tab-pane fade" id="biodata-tab-pane" role="tabpanel" aria-labelledby="biodata-tab" tabindex="0">
            <div class="card shadow mb-4">
              <div class="card-header bg-primary text-white">
                <h5 class="mb-0"><i class="fas fa-user me-2"></i>Biodata Mahasiswa</h5>
              </div>
              <div class="card-body">
                <div class="mb-3">
                  <label for="txtIdLine" class="form-label">ID Line</label>
                  <asp:TextBox ID="txtIdLine" runat="server" CssClass="form-control"></asp:TextBox>
                </div>
                <div class="mb-3">
                  <label for="txtInstagram" class="form-label">Instagram</label>
                  <asp:TextBox ID="txtInstagram" runat="server" CssClass="form-control"></asp:TextBox>
                </div>
                <div class="mb-3">
                  <label for="txtWhatsapp" class="form-label">No WhatsApp</label>
                  <asp:TextBox ID="txtWhatsapp" runat="server" CssClass="form-control"></asp:TextBox>
                </div>
                <div class="mb-3">
                  <label for="ddlMinat" class="form-label">Anda Beminat Mengikuti UKM?</label>
                  <asp:DropDownList ID="ddlMinat" runat="server" CssClass="form-select">
                    <asp:ListItem Text="-- Pilih Jawaban --" Value="" Selected="True"></asp:ListItem>
                    <asp:ListItem Text="Ya" Value="Y"></asp:ListItem>
                    <asp:ListItem Text="Tidak" Value="T"></asp:ListItem>
                  </asp:DropDownList>
                </div>
                <div class="d-flex justify-content-between mt-4">
                  <button type="button" class="btn btn-secondary" id="btnBackToUkm"><i class="fas fa-arrow-left me-2"></i>Kembali</button>
                  <asp:Button ID="btnSubmitBiodata" runat="server" CssClass="btn btn-success" Text="Kirim" OnClick="btnSubmitBiodata_Click" OnClientClick="return validateBiodataForm();" />
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Confirmation Modal -->
        <div class="modal fade" id="confirmationModal" tabindex="-1" aria-labelledby="confirmationModalLabel" aria-hidden="true">
          <div class="modal-dialog modal-dialog-centered modal-sm">
            <div class="modal-content border-0 shadow-lg">
              <div class="modal-header border-0 pb-2">
                <h5 class="modal-title" id="confirmationModalLabel">
                  <i class="fas fa-exclamation-triangle text-warning me-2"></i>Konfirmasi
                </h5>
              </div>
              <div class="modal-body text-center py-4">
                <p class="mb-4">Anda yakin ingin meninggalkan halaman ini?</p>
                <div class="d-flex justify-content-center gap-3">
                  <button type="button" class="btn btn-outline-secondary px-4" id="btnConfirmNo">
                    Tidak
                  </button>
                  <button type="button" class="btn btn-danger px-4" id="btnConfirmYes">
                    Ya
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <!-- Success Modal -->
        <div class="modal fade" id="successModal" tabindex="-1" aria-labelledby="successModalLabel" aria-hidden="true">
          <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content border-0 shadow-lg">
              <div class="modal-body text-center p-5">
                <div class="success-icon mb-4">
                  <i class="fas fa-check-circle" style="font-size: 4rem; color: #28a745;"></i>
                </div>
                <h3 class="text-success mb-3">Berhasil!</h3>
                <p class="text-muted mb-4">Pilihan UKM Anda berhasil disimpan.<br>Silakan lengkapi biodata Anda.</p>
                <button type="button" class="btn btn-success btn-lg px-5" id="btnOkSuccess">
                  <i class="fas fa-arrow-right me-2"></i>Lanjutkan
                </button>
              </div>
            </div>
          </div>
        </div>
        
      </form>
    </div>
  </section>
</div>

<script>
        // Validasi form biodata sebelum submit
        function validateBiodataForm() {
            console.log('validateBiodataForm called');
            
            var idLine = document.getElementById('<%= txtIdLine.ClientID %>').value.trim();
            var instagram = document.getElementById('<%= txtInstagram.ClientID %>').value.trim();
            var whatsapp = document.getElementById('<%= txtWhatsapp.ClientID %>').value.trim();
            var minat = document.getElementById('<%= ddlMinat.ClientID %>').value;
            
            console.log('Form values:', {
                idLine: idLine,
                instagram: instagram,
                whatsapp: whatsapp,
                minat: minat
            });
            
            // Minimal validation - at least one field should be filled
            if (idLine === '' && instagram === '' && whatsapp === '' && minat === '') {
                alert('Mohon isi minimal satu field biodata!');
                return false;
            }
            
            console.log('Form validation passed');
            return true;
        }
        </script>

<style type="text/css">
  /* Enhanced modal styling */
  .modal-content {
    border-radius: 15px;
    overflow: hidden;
  }
  
  
  /* Confirmation modal styling */
  #confirmationModal .modal-content {
    border-radius: 12px;
  }
  
  #confirmationModal .btn {
    border-radius: 8px;
    font-weight: 500;
  }
  
  .success-icon {
    animation: bounceIn 0.6s ease-out;
  }
  
  @keyframes bounceIn {
    0% {
      transform: scale(0.3);
      opacity: 0;
    }
    50% {
      transform: scale(1.05);
    }
    70% {
      transform: scale(0.9);
    }
    100% {
      transform: scale(1);
      opacity: 1;
    }
  }
  
  .btn-success {
    background: linear-gradient(45deg, #28a745, #20c997);
    border: none;
    border-radius: 25px;
    transition: all 0.3s ease;
  }
  
  .btn-success:hover {
    background: linear-gradient(45deg, #218838, #1ea080);
    transform: translateY(-2px);
    box-shadow: 0 5px 15px rgba(40, 167, 69, 0.3);
  }
  
  /* Ensure biodata section is properly styled */
  #biodata-tab-pane {
    min-height: 400px;
    display: block !important;
  }
  
  #biodataSection {
    min-height: 400px;
  }
  
  #biodataSection .form-control, #biodataSection .form-select,
  #biodata-tab-pane .form-control, #biodata-tab-pane .form-select {
    border-radius: 8px;
    border: 2px solid #e9ecef;
    padding: 12px 15px;
    font-size: 14px;
    transition: all 0.3s ease;
  }
  
  #biodataSection .form-control:focus, #biodataSection .form-select:focus,
  #biodata-tab-pane .form-control:focus, #biodata-tab-pane .form-select:focus {
    border-color: #007bff;
    box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
    transform: translateY(-1px);
  }
  
  #biodataSection .form-label,
  #biodata-tab-pane .form-label {
    font-weight: 600;
    color: #495057;
    margin-bottom: 8px;
  }
  
  /* Ensure modal is visible */
  .modal {
    display: none;
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    z-index: 1050;
    outline: 0;
  }
  
  .modal.show {
    display: block;
  }
  
  .modal-dialog {
    position: relative;
    width: auto;
    margin: 0.5rem;
    pointer-events: none;
  }
  
  @media (min-width: 576px) {
    .modal-dialog {
      max-width: 500px;
      margin: 1.75rem auto;
    }
  }
  
  .modal-content {
    position: relative;
    display: flex;
    flex-direction: column;
    width: 100%;
    pointer-events: auto;
    background-color: #fff;
    background-clip: padding-box;
    border: 1px solid rgba(0,0,0,.2);
    border-radius: 0.3rem;
    outline: 0;
  }
  
  .modal-backdrop {
    position: fixed;
    top: 0;
    left: 0;
    z-index: 1040;
    width: 100vw;
    height: 100vh;
    background-color: #000;
  }
  
  .modal-backdrop.fade {
    opacity: 0;
  }
  
  .modal-backdrop.show {
    opacity: 0.5;
  }
  
  
  /* Form Check Customization */
  .form-check {
    padding-left: 0;
    margin: 0;
    width: 100%;
  }
  
  .form-check-input {
    margin: 0 0.75rem 0 0;
    width: 1.25rem;
    height: 1.25rem;
    border: 2px solid #d1d3e2;
    cursor: pointer;
  }
  
  .form-check-input:checked {
    background-color: #4e73df;
    border-color: #4e73df;
    box-shadow: none;
  }
  
  .form-check-label {
    font-weight: 500;
    color: #5a5c69;
    cursor: pointer;
    padding: 0.5rem 0;
    width: 100%;
  }
  
  /* Answer Option Styling */
  .answer-option {
    border: 1px solid #e3e6f0;
    border-radius: 0.5rem;
    margin-bottom: 0.75rem;
    transition: all 0.2s;
    background-color: #fff;
    cursor: pointer;
    padding: 0.75rem 1.25rem;
    display: flex;
    align-items: flex-start;
  }
  
  .answer-option:hover {
    border-color: #b7b9cc;
    background-color: #f8f9fc;
  }
  
  .answer-option.active {
    border-color: #4e73df;
    background-color: #f0f4ff;
  }
  
  .answer-option .form-check {
    display: flex;
    margin: 0;
    padding: 0;
    width: 100%;
    align-items: flex-start;
    gap: 0.75rem;
  }
  
  .answer-option .form-check-input {
    margin-top: 0.25rem;
    margin-left: 0;
    flex-shrink: 0;
    position: relative;
  }
  
  .answer-option .form-check-label {
    color: #5a5c69;
    font-weight: 500;
    padding: 0;
    width: 100%;
    word-break: break-word;
    white-space: normal;
    overflow: visible;
  }
  
  .answer-option.active .form-check-label {
    color: #2e59d9;
  }
  
  /* Custom styling for UKM checkboxes */
  .ukm-option {
    background-color: #fff;
    transition: all 0.2s ease-in-out;
  display: flex;
  align-items: center;
  justify-content: space-between;   /* pastikan label di kiri, checkbox di kanan */
  column-gap: 0.75rem;              /* jarak konsisten antara label dan checkbox */
}

.ukm-option .form-check-label {
  margin: 0;
  flex: 1 1 auto;                   /* biarkan teks mengambil ruang yang tersedia */
  line-height: 1.25;                /* bikin sejajar lebih enak dilihat */
}
  
  .ukm-option:hover {
    background-color: #f8f9fc;
    border-color: #4e73df !important;
    cursor: pointer;
  }
  
  .ukm-option .form-check-input:checked ~ .form-check-label {
    color: #4e73df;
    font-weight: 600;
  }
  
.ukm-checkbox {
  flex: 0 0 20px;                   /* lebar fix agar kolom checkbox sejajar */
  width: 20px;
  height: 20px;                     /* opsional: samakan size */
  margin-left: 0 !important;
  position: relative !important;
}

  .ukm-option .form-check-input:checked {
    background-color: #4e73df;
    border-color: #4e73df;
  }
  
  /* Card Styling */
  .card {
    border: none;
    border-radius: 0.5rem;
    box-shadow: 0 0.15rem 1.75rem 0 rgba(58, 59, 69, 0.1);
    margin-bottom: 1.5rem;
  }
  
  .card-header {
    font-weight: 700;
    background-color: #fff;
    border-bottom: 1px solid #e3e6f0;
    padding: 1.25rem 1.5rem;
  }
  .question-text {
    font-size: 1.1rem;
    margin-bottom: 1rem;
    font-weight: 500;
  }
  .form-check {
    padding: 0.5rem 0;
  }
  .form-check-input {
    margin-right: 0.5rem;
  }
</style>

<script type="text/disabled">
    // Global variables
    var selectedUkms = [];
    var recommendedUkms = [];
    var allUkms = [
        { id: 'UKM001', name: 'UKM Olahraga', category: 'olahraga' },
        { id: 'UKM002', name: 'UKM Seni', category: 'seni' },
        { id: 'UKM003', name: 'UKM Kesenian Tradisional', category: 'seni' },
        { id: 'UKM004', name: 'UKM Paduan Suara', category: 'musik' },
        { id: 'UKM005', name: 'UKM Pencak Silat', category: 'beladiri' },
        { id: 'UKM006', name: 'UKM Pramuka', category: 'sosial' },
        { id: 'UKM007', name: 'UKM KSR-PMI', category: 'sosial' },
        { id: 'UKM008', name: 'UKM Koperasi Mahasiswa', category: 'kewirausahaan' },
        { id: 'UKM009', name: 'UKM Jurnalistik', category: 'media' },
        { id: 'UKM010', name: 'UKM Fotografi', category: 'media' },
        { id: 'UKM011', name: 'UKM Robotik', category: 'teknologi' },
        { id: 'UKM012', name: 'UKM Bahasa Asing', category: 'bahasa' },
        { id: 'UKM013', name: 'UKM Debat', category: 'akademik' },
        { id: 'UKM014', name: 'UKM Pecinta Alam', category: 'alam' },
        { id: 'UKM015', name: 'UKM Bola Basket', category: 'olahraga' },
        { id: 'UKM016', name: 'UKM Futsal', category: 'olahraga' },
        { id: 'UKM017', name: 'UKM Badminton', category: 'olahraga' },
        { id: 'UKM018', name: 'UKM Tenis Meja', category: 'olahraga' },
        { id: 'UKM019', name: 'UKM Voli', category: 'olahraga' },
        { id: 'UKM020', name: 'UKM Taekwondo', category: 'beladiri' }
    ];

    $(document).ready(function() {
        // Initialize variables
        let currentQuestion = 0;
        let autoAdvance = false; // Fix: Add missing autoAdvance variable
        
        // Mengambil pertanyaan dari hidden field yang diisi dari database
        let questions = [];
        const questionsJson = $('#<%= hdnQuestions.ClientID %>').val();
        if (questionsJson) {
            questions = JSON.parse(questionsJson);
            console.log('Pertanyaan berhasil dimuat dari database:', questions.length, 'pertanyaan');
        } else {
            console.error('Tidak ada pertanyaan yang ditemukan di hidden field');
            alert('Error: Pertanyaan tidak dapat dimuat dari database. Silakan refresh halaman atau hubungi administrator.');
        }
        
        // Skala Likert dibalik: 1 = Sangat Setuju, 2 = Setuju, 3 = Ragu-Ragu/Netral, 4 = Tidak Setuju, 5 = Sangat Tidak Setuju
        // Nilai terkecil berarti persetujuan tertinggi, nilai terbesar berarti ketidaksetujuan tertinggi.
        const answerOptions = [
            { value: 1, text: "Sangat Setuju" },
            { value: 2, text: "Setuju" },
            { value: 3, text: "Ragu-Ragu" },
            { value: 4, text: "Tidak Setuju" },
            { value: 5, text: "Sangat Tidak Setuju" }
        ];
        
        // Initialize jawabanMahasiswa object
        let jawabanMahasiswa = {};

        // Pertanyaan khusus yang tidak menggunakan skala Likert
        // Gunakan indeks berbasis 0 untuk menentukan pertanyaan ke-21 dan ke-22
        const specialGenderIndex = 20;   // 0-based index untuk pertanyaan "Jenis kelamin Anda" (id_pertanyaan = 21)
        const specialDiseaseIndex = 21;  // 0-based index untuk pertanyaan "Apakah Anda memiliki penyakit bawaan?" (id_pertanyaan = 22)

        // Menyimpan jawaban khusus dalam sebuah objek terpisah
        // gender: "Laki-laki" atau "Perempuan"
        // disease: "Ya" atau "Tidak"
        // diseaseDetail: teks penyakit bawaan jika jawab "Ya"
        let additionalAnswers = {
            gender: '',
            disease: '',
            diseaseDetail: ''
        };
        
        // Load saved jawabanMahasiswa if they exist
        const savedAnswers = $('#<%= hdnAnswers.ClientID %>').val();
        if (savedAnswers) {
            try {
                jawabanMahasiswa = JSON.parse(savedAnswers);
            } catch (e) {
                console.error('Error parsing saved answers:', e);
            }
        }
        
        // Set total questions count
        $('#totalQuestions').text(questions.length);
        
        // Debug information
        console.log('jQuery version:', $.fn.jquery);
        console.log('Bootstrap version:', typeof bootstrap !== 'undefined' ? bootstrap.Tooltip.VERSION : 'Bootstrap not loaded');
        console.log('Modal element exists:', $('#questionModal').length > 0);
        
        // Direct modal show function
        function showQuestionModal() {
            console.log('Showing question modal');
            
            // Show the first question
            showQuestion(0);
            
            // Directly manipulate the modal
            const modal = document.getElementById('questionModal');
            if (modal) {
                modal.style.display = 'block';
                modal.classList.add('show');
                document.body.classList.add('modal-open');
                
                // Add backdrop
                const backdrop = document.createElement('div');
                backdrop.className = 'modal-backdrop fade show';
                document.body.appendChild(backdrop);
                
                // Hide start card
                const startCard = document.getElementById('startCard');
                if (startCard) startCard.style.display = 'none';
                
                console.log('Modal should be visible now');
            } else {
                console.error('Modal element not found!');
            }
        }
        
        // Set up start button
        const startButton = document.getElementById('btnStart');
        if (startButton) {
            startButton.onclick = showQuestionModal;
        } else {
            console.error('Start button not found!');
        }
        
        // Close modal handler for the close button - show confirmation
        $('#questionModal .btn-close').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            
            // Show confirmation modal
            const confirmModal = new bootstrap.Modal(document.getElementById('confirmationModal'));
            confirmModal.show();
        });
        
        // Confirmation modal handlers
        $('#btnConfirmYes').on('click', function() {
            // Close confirmation modal
            const confirmModal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
            if (confirmModal) {
                confirmModal.hide();
            }
            
            // Close question modal
            $('#questionModal').removeClass('show').css('display', 'none');
            $('.modal-backdrop').remove();
            $('body').removeClass('modal-open');
            
            // Show start card again (back to Tes Minat)
            $('#startCard').show();
            
            // Reset questionnaire state
            currentQuestion = 0;
            answers = {};
            
            // Reset progress bar
            $('.progress-bar').css('width', '5%').attr('aria-valuenow', 5);
            
            // Reset buttons
            $('#btnPrev').prop('disabled', true);
            $('#btnNext').show();
            $('#btnSubmit').hide();
        });
        
        $('#btnConfirmNo').on('click', function() {
            // Just close confirmation modal and stay in questionnaire
            const confirmModal = bootstrap.Modal.getInstance(document.getElementById('confirmationModal'));
            if (confirmModal) {
                confirmModal.hide();
            }
        });
        
        // Error handling
        $(document).ajaxError(function(event, jqXHR, settings, error) {
            console.error('AJAX Error:', error);
        });
        
        // Previous button click handler
        $('#btnPrev').click(function() {
            saveCurrentAnswer();
            showQuestion(currentQuestion - 1);
        });
        
        
        // Next button click handler
        $('#btnNext').click(function() {
            if (validateCurrentAnswer()) {
                saveCurrentAnswer();
                showQuestion(currentQuestion + 1);
            } else {
                alert('Silakan pilih jawaban terlebih dahulu.');
            }
        });
        
        // Handle next to results button click
        $('#btnNextToResults').click(function() {
            // Save disease information
            var penyakitBawaan = $('#<%= txtPenyakitBawaan.ClientID %>').val();
            $('#<%= hdnPenyakitBawaan.ClientID %>').val(penyakitBawaan);
            
            // Switch to UKM tab
            var ukmTab = new bootstrap.Tab(document.getElementById('ukm-tab'));
            ukmTab.show();
        });
        
        // Handle back to test button click
        $('#btnBackToTest').click(function() {
            var testTab = new bootstrap.Tab(document.getElementById('test-tab'));
            testTab.show();
        });
        
    
        $('#btnNextToBiodata').click(function() {
            if (selectedUkms.length === 0) {
                alert('Silakan pilih minimal satu UKM');
                return;
            }
            
            // Update selected UKMs
            updateSelectedUkms();
            
            // Enable and switch to biodata tab
            $('#biodata-tab').prop('disabled', false);
            var biodataTab = new bootstrap.Tab(document.getElementById('biodata-tab'));
            biodataTab.show();
        });
        
        // Handle back to UKM button click
        $('#btnBackToUkm').click(function() {
            $('#ukm-tab').tab('show');
        });
        
        // Handle UKM checkbox changes
        $(document).on('change', '.ukm-checkbox', function() {
            const checkbox = $(this);
            const ukmOption = checkbox.closest('.ukm-option');
            
            // Add visual feedback
            if (checkbox.is(':checked')) {
                ukmOption.css('background-color', '#f0f4ff');
            } else {
                ukmOption.css('background-color', '#fff');
            }
            
            updateSelectedUkms();
        });
        
        // Add click handler for the whole UKM option div
        $(document).on('click', '.ukm-option', function(e) {
            if (!$(e.target).is('input')) {
                const checkbox = $(this).find('.ukm-checkbox');
                checkbox.prop('checked', !checkbox.prop('checked')).trigger('change');
            }
        });
        
        // Submit button click handler
        $('#btnSubmit').click(function(e) {
            e.preventDefault();
            
            if (validateCurrentAnswer()) {
                saveCurrentAnswer();
                
                // Save all jawabanMahasiswa to hidden field
                const answersJson = JSON.stringify(jawabanMahasiswa);
                $('#<%= hdnAnswers.ClientID %>').val(answersJson);
                // Simpan jawaban khusus ke hidden fields
                $('#<%= hdnGender.ClientID %>').val(additionalAnswers.gender);
                $('#<%= hdnPenyakit.ClientID %>').val(additionalAnswers.disease);
                $('#<%= hdnDetailPenyakit.ClientID %>').val(additionalAnswers.diseaseDetail);
                console.log('Answers saved:', answersJson);
                console.log('Additional answers:', additionalAnswers);
                
                // Show loading state
                const submitBtn = $(this);
                submitBtn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Memproses...');
                
                // Hide modal
                const modal = bootstrap.Modal.getInstance(document.getElementById('questionModal'));
                modal.hide();
                
                // Show processing message
                $('#litPesan').html('<div class="alert alert-info">Sedang memproses rekomendasi UKM...</div>');
                
                // Trigger the hidden button click directly instead of __doPostBack
                setTimeout(function() {
                    try {
                        console.log('Submitting form...');
                        // Submit the form using the hidden button
                        $('#<%= btnProcessAnswers.ClientID %>').trigger('click');
                        
                        // After processing, switch to UKM tab and enable it
                        $('#test-tab').removeClass('active');
                        $('#ukm-tab').prop('disabled', false).addClass('active');
                        $('#test-tab-pane').removeClass('show active');
                        $('#ukmSection').show();
                        
                        // Initialize checkbox handling
                        $('.ukm-checkbox').off('change').on('change', function() {
                            updateSelectedUkms();
                        });
                    } catch (err) {
                        console.error('Error submitting form:', err);
                        $('#litPesan').html('<div class="alert alert-danger">Terjadi kesalahan saat memproses jawaban. Silakan coba lagi.</div>');
                        submitBtn.prop('disabled', false).html('Selesai');
                    }
	                }, 500);
	            } else {
	                alert('Silakan pilih jawaban terlebih dahulu.');
	            }
	        });

        
        // Show question at the given index
        function showQuestion(index) {
            if (index < 0 || index >= questions.length) return;
            
            currentQuestion = index;
            
            // Update question number and text
            $('#questionNumber').text(index + 1);
            $('#questionText').text(questions[index]);
            
            // Generate answer options
            let optionsHtml = '';
            // Jika pertanyaan khusus (gender atau penyakit), tampilkan opsi khusus
            if (index === specialGenderIndex) {
                // Opsi: Laki-laki / Perempuan
                const genderOptions = [
                    { value: 'Laki-laki', text: 'Laki-laki' },
                    { value: 'Perempuan', text: 'Perempuan' }
                ];
                genderOptions.forEach(opt => {
                    const isChecked = additionalAnswers.gender === opt.value;
                    optionsHtml += `
                        <div class="answer-option ${isChecked ? 'active' : ''}" data-value="${opt.value}">
                            <div class="form-check">
                                <input class="form-check-input" type="radio" name="answer" id="gender_${opt.value}" value="${opt.value}" ${isChecked ? 'checked' : ''}>
                                <label class="form-check-label" for="gender_${opt.value}">${opt.text}</label>
                            </div>
                        </div>
                    `;
                });
            } else if (index === specialDiseaseIndex) {
                // Opsi: Ya / Tidak, dengan textarea kondisi penyakit jika Ya
                const diseaseOptions = [
                    { value: 'Ya', text: 'Ya' },
                    { value: 'Tidak', text: 'Tidak' }
                ];
                diseaseOptions.forEach(opt => {
                    const isChecked = additionalAnswers.disease === opt.value;
                    optionsHtml += `
                        <div class="answer-option ${isChecked ? 'active' : ''}" data-value="${opt.value}">
                            <div class="form-check">
                                <input class="form-check-input" type="radio" name="answer" id="disease_${opt.value}" value="${opt.value}" ${isChecked ? 'checked' : ''}>
                                <label class="form-check-label" for="disease_${opt.value}">${opt.text}</label>
                            </div>
                        </div>
                    `;
                });
                // Tambahkan input untuk detail penyakit dengan kondisi tersembunyi
                const diseaseDetail = additionalAnswers.diseaseDetail || '';
                optionsHtml += `
                    <div id="diseaseDetailContainer" style="display: ${additionalAnswers.disease === 'Ya' ? 'block' : 'none'}; margin-top: 1rem;">
                        <label for="diseaseDetail" class="form-label">Sebutkan penyakit bawaan Anda</label>
                        <input type="text" class="form-control" id="diseaseDetail" value="${diseaseDetail}" placeholder="Masukkan nama penyakit" />
                    </div>
                `;
            } else {
                // Pertanyaan reguler menggunakan skala Likert
                answerOptions.forEach(option => {
                    // Gunakan kunci 1-based untuk jawabanMahasiswa. currentQuestion berbasis 0, tambahkan 1 agar cocok dengan backend.
                    const isChecked = jawabanMahasiswa[currentQuestion + 1] === option.value.toString();
                    optionsHtml += `
                        <div class="answer-option ${isChecked ? 'active' : ''}" data-value="${option.value}">
                            <div class="form-check">
                                <input class="form-check-input" type="radio" 
                                       name="answer" id="option${option.value}" 
                                       value="${option.value}" ${isChecked ? 'checked' : ''}>
                                <label class="form-check-label" for="option${option.value}">
                                    ${option.text}
                                </label>
                            </div>
                        </div>
                    `;
                });
            }

            $('#answerOptions').html(optionsHtml);
            
            // Add click handler for answer options
            $('.answer-option').off('click').on('click', function() {
                const value = $(this).data('value');
                // Hilangkan kelas active dari semua opsi dan centang radio
                $('.answer-option').removeClass('active');
                $(this).addClass('active');
                $('input[name="answer"]').prop('checked', false);
                // Temukan radio input di dalam opsi ini dan tandai sebagai checked
                $(this).find('input[type="radio"]').prop('checked', true);

                // Jika ini pertanyaan penyakit, tampilkan atau sembunyikan detail penyakit
                if (currentQuestion === specialDiseaseIndex) {
                    if (value === 'Ya') {
                        $('#diseaseDetailContainer').show();
                        $('#diseaseDetail').prop('required', true);
                    } else {
                        $('#diseaseDetailContainer').hide();
                        $('#diseaseDetail').prop('required', false);
                        $('#diseaseDetail').val('');
                    }
                }

/* Duplicate code removed due to added tabs:
// Handle next to biodata button click
$('#btnNextToBiodata').click(function() {
    if (selectedUkms.length === 0) {
        alert('Silakan pilih minimal satu UKM');
        return;
    }
    
    // Update selected UKMs
    updateSelectedUkms();
    
    // Switch to biodata tab
    var biodataTab = new bootstrap.Tab(document.getElementById('biodata-tab'));
    biodataTab.show();
});

// Handle back to UKM button click
$('#btnBackToUkm').click(function() {
    var ukmTab = new bootstrap.Tab(document.getElementById('ukm-tab'));
    ukmTab.show();
});

// Handle UKM checkbox changes
$(document).on('change', '.ukm-checkbox', function() {
    updateSelectedUkms();
});

// Submit button click handler
$('#btnSubmit').click(function(e) {
    e.preventDefault();
    
    if (validateCurrentAnswer()) {
        saveCurrentAnswer();
        
        // Save all jawabanMahasiswa to hidden field
        const answersJson = JSON.stringify(jawabanMahasiswa);
        $('#<%= hdnAnswers.ClientID %>').val(answersJson);
        // Simpan jawaban khusus ke hidden fields
        $('#<%= hdnGender.ClientID %>').val(additionalAnswers.gender);
        $('#<%= hdnPenyakit.ClientID %>').val(additionalAnswers.disease);
        $('#<%= hdnDetailPenyakit.ClientID %>').val(additionalAnswers.diseaseDetail);
        console.log('Answers saved:', answersJson);
        console.log('Additional answers:', additionalAnswers);
        
        // Show loading state
        const submitBtn = $(this);
        submitBtn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Memproses...');
        
        // Hide modal
        const modal = bootstrap.Modal.getInstance(document.getElementById('questionModal'));
        modal.hide();
        
        // Show processing message
        $('#litPesan').html('<div class="alert alert-info">Sedang memproses rekomendasi UKM...</div>');
        
        // Trigger the hidden button click directly instead of __doPostBack
        setTimeout(function() {
            try {
                console.log('Submitting form...');
                // Submit the form using the hidden button
                $('#<%= btnProcessAnswers.ClientID %>').trigger('click');
            } catch (err) {
                console.error('Error submitting form:', err);
                $('#litPesan').html('<div class="alert alert-danger">Terjadi kesalahan saat memproses jawaban. Silakan coba lagi.</div>');
                submitBtn.prop('disabled', false).html('Selesai');
            }
        }, 500);
    } else {
        alert('Silakan pilih jawaban terlebih dahulu.');
    }
});

// Show question at the given index
function showQuestion(index) {
    if (index < 0 || index >= questions.length) return;
    
    currentQuestion = index;
    
    // Update question number and text
    $('#questionNumber').text(index + 1);
    $('#questionText').text(questions[index]);
    
    // Generate answer options
    let optionsHtml = '';
    // Jika pertanyaan khusus (gender atau penyakit), tampilkan opsi khusus
    if (index === specialGenderIndex) {
        // Opsi: Laki-laki / Perempuan
        const genderOptions = [
            { value: 'Laki-laki', text: 'Laki-laki' },
            { value: 'Perempuan', text: 'Perempuan' }
        ];
        genderOptions.forEach(opt => {
            const isChecked = additionalAnswers.gender === opt.value;
            optionsHtml += `
                <div class="answer-option ${isChecked ? 'active' : ''}" data-value="${opt.value}">
                    <div class="form-check">
                        <input class="form-check-input" type="radio" name="answer" id="gender_${opt.value}" value="${opt.value}" ${isChecked ? 'checked' : ''}>
                        <label class="form-check-label" for="gender_${opt.value}">${opt.text}</label>
                    </div>
                </div>
            `;
        });
    } else if (index === specialDiseaseIndex) {
        // Opsi: Ya / Tidak, dengan textarea kondisi penyakit jika Ya
        const diseaseOptions = [
            { value: 'Ya', text: 'Ya' },
            { value: 'Tidak', text: 'Tidak' }
        ];
        diseaseOptions.forEach(opt => {
            const isChecked = additionalAnswers.disease === opt.value;
            optionsHtml += `
                <div class="answer-option ${isChecked ? 'active' : ''}" data-value="${opt.value}">
                    <div class="form-check">
                        <input class="form-check-input" type="radio" name="answer" id="disease_${opt.value}" value="${opt.value}" ${isChecked ? 'checked' : ''}>
                        <label class="form-check-label" for="disease_${opt.value}">${opt.text}</label>
                    </div>
                </div>
            `;
        });
        // Tambahkan input untuk detail penyakit dengan kondisi tersembunyi
        const diseaseDetail = additionalAnswers.diseaseDetail || '';
        optionsHtml += `
            <div id="diseaseDetailContainer" style="display: ${additionalAnswers.disease === 'Ya' ? 'block' : 'none'}; margin-top: 1rem;">
                <label for="diseaseDetail" class="form-label">Sebutkan penyakit bawaan Anda</label>
                <input type="text" class="form-control" id="diseaseDetail" value="${diseaseDetail}" placeholder="Masukkan nama penyakit" />
            </div>
        `;
    } else {
        // Pertanyaan reguler menggunakan skala Likert
        answerOptions.forEach(option => {
            // Gunakan kunci 1-based untuk jawabanMahasiswa. currentQuestion berbasis 0, tambahkan 1 agar cocok dengan backend.
            const isChecked = jawabanMahasiswa[currentQuestion + 1] === option.value.toString();
            optionsHtml += `
                <div class="answer-option ${isChecked ? 'active' : ''}" data-value="${option.value}">
                    <div class="form-check">
                        <input class="form-check-input" type="radio" 
                               name="answer" id="option${option.value}" 
                               value="${option.value}" ${isChecked ? 'checked' : ''}>
                        <label class="form-check-label" for="option${option.value}">
                            ${option.text}
                        </label>
                    </div>
                </div>
            `;
        });
    }

    $('#answerOptions').html(optionsHtml);
    
    // Add click handler for answer options
    $('.answer-option').off('click').on('click', function() {
        const value = $(this).data('value');
        // Hilangkan kelas active dari semua opsi dan centang radio
        $('.answer-option').removeClass('active');
        $(this).addClass('active');
        $('input[name="answer"]').prop('checked', false);
        // Temukan radio input di dalam opsi ini dan tandai sebagai checked
        $(this).find('input[type="radio"]').prop('checked', true);

        // Jika ini pertanyaan penyakit, tampilkan atau sembunyikan detail penyakit
        if (currentQuestion === specialDiseaseIndex) {
            if (value === 'Ya') {
                $('#diseaseDetailContainer').show();
                $('#diseaseDetail').prop('required', true);
            } else {
                $('#diseaseDetailContainer').hide();
                $('#diseaseDetail').prop('required', false);
                $('#diseaseDetail').val('');
            }
        }

        // Auto-advance to next question if enabled
        if (autoAdvance) {
            setTimeout(() => {
                if (currentQuestion === questions.length - 1) {
                    saveAnswersAndShowDiseaseSection();
                } else {
                    saveCurrentAnswer();
                    showQuestion(currentQuestion + 1);
                }
            }, 300);
        }
    });
    
    // Add hover effect
    $('.answer-option').hover(
        function() {
            if (!$(this).hasClass('active')) {
                $(this).css('border-color', '#b7b9cc');
            }
        },
        function() {
            if (!$(this).hasClass('active')) {
                $(this).css('border-color', '#e3e6f0');
            }
        }
    );
    
    // Update navigation buttons
    $('#btnPrev').prop('disabled', index === 0);
    $('#btnNext').toggle(index < questions.length - 1);
    $('#btnSubmit').toggle(index === questions.length - 1);
    
    // Update progress
    const progress = Math.round(((index + 1) / questions.length) * 100);
    $('.progress-bar').css('width', progress + '%').attr('aria-valuenow', progress);
}

// Save current answer
function saveCurrentAnswer() {
    const selectedOption = $("input[name='answer']:checked");
    if (selectedOption.length > 0) {
        const value = selectedOption.val();
        // Pertanyaan jenis kelamin (id = 21)
        if (currentQuestion === specialGenderIndex) {
            additionalAnswers.gender = value;
        }
        // Pertanyaan penyakit bawaan (id = 22)
        else if (currentQuestion === specialDiseaseIndex) {
            additionalAnswers.disease = value;
            if (value === 'Ya') {
                // Simpan detail penyakit
                const detail = $('#diseaseDetail').val() || '';
                additionalAnswers.diseaseDetail = detail;
            } else {
                additionalAnswers.diseaseDetail = '';
            }
        }
        // Pertanyaan reguler
        else {
            // Simpan jawaban dalam jawabanMahasiswa dengan key 1-based
            jawabanMahasiswa[currentQuestion + 1] = value;
        }
    }
}

// Validate if an answer is selected
function validateCurrentAnswer() {
    const checked = $("input[name='answer']:checked").length > 0;
    // Jika pertanyaan jenis kelamin, hanya perlu memilih opsi
    if (currentQuestion === specialGenderIndex) {
        return checked;
    }
    // Jika pertanyaan penyakit bawaan, cek validasi tambahan
    if (currentQuestion === specialDiseaseIndex) {
        if (!checked) return false;
        const value = $("input[name='answer']:checked").val();
        if (value === 'Ya') {
            const detail = $('#diseaseDetail').val();
            return detail && detail.trim().length > 0;
        }
        return true;
    }
    // Pertanyaan reguler, harus pilih salah satu
    return checked;
}

// Save answers and show disease section
function saveAnswersAndShowDiseaseSection() {
    // Save the last answer
    saveCurrentAnswer();
    showDiseaseSection();
    
    // Generate recommendations based on answers
    generateRecommendations();
}

// Generate UKM recommendations based on answers
function generateRecommendations() {
    // Simple recommendation logic based on answer scores
    // In a real app, this would be more sophisticated
    
    // Reset recommendations
    recommendedUkms = [];
    
    // Calculate scores for each UKM based on answers
    allUkms.forEach(function(ukm) {
        var score = 0;
        
        // Simple scoring based on answer patterns
        // In a real app, this would be more sophisticated
        for (var q in jawabanMahasiswa) {
            var answer = jawabanMahasiswa[q];
            
            // Example: Higher answers (4-5) for certain questions increase score for certain UKM categories
            if (answer >= 4) {
                if ((ukm.category === 'olahraga' && (q == 1 || q == 5 || q == 9)) ||
                    (ukm.category === 'seni' && (q == 2 || q == 6 || q == 10)) ||
                    (ukm.category === 'sosial' && (q == 3 || q == 7 || q == 11)) ||
                    (ukm.category === 'teknologi' && (q == 4 || q == 8 || q == 12))) {
                    score += 2;
                }
            }
        }
        
        // Add to recommended if score is above threshold
        if (score >= 4) {
            recommendedUkms.push({
                id: ukm.id,
                name: ukm.name,
                category: ukm.category,
                score: score
            });
            $('.answer-option').hover(
                function() {
                    if (!$(this).hasClass('active')) {
                        $(this).css('border-color', '#b7b9cc');
                    }
                },
                function() {
                    if (!$(this).hasClass('active')) {
                        $(this).css('border-color', '#e3e6f0');
                    }
                }
            );
            
            // Update navigation buttons
            $('#btnPrev').prop('disabled', index === 0);
            $('#btnNext').toggle(index < questions.length - 1);
            $('#btnSubmit').toggle(index === questions.length - 1);
            
            // Update progress
            const progress = Math.round(((index + 1) / questions.length) * 100);
            $('.progress-bar').css('width', progress + '%').attr('aria-valuenow', progress);
        }
        
        // Save current answer
        function saveCurrentAnswer() {
            const selectedOption = $("input[name='answer']:checked");
            if (selectedOption.length > 0) {
                const value = selectedOption.val();
                // Pertanyaan jenis kelamin (id = 21)
                if (currentQuestion === specialGenderIndex) {
                    additionalAnswers.gender = value;
                }
                // Pertanyaan penyakit bawaan (id = 22)
                else if (currentQuestion === specialDiseaseIndex) {
                    additionalAnswers.disease = value;
                    if (value === 'Ya') {
                        // Simpan detail penyakit
                        const detail = $('#diseaseDetail').val() || '';
                        additionalAnswers.diseaseDetail = detail;
                    } else {
                        additionalAnswers.diseaseDetail = '';
                    }
                }
                // Pertanyaan reguler
                else {
                    // Simpan jawaban dalam jawabanMahasiswa dengan key 1-based
                    jawabanMahasiswa[currentQuestion + 1] = value;
                }
            }
        }
        
        // Validate if an answer is selected
        function validateCurrentAnswer() {
            const checked = $("input[name='answer']:checked").length > 0;
            // Jika pertanyaan jenis kelamin, hanya perlu memilih opsi
            if (currentQuestion === specialGenderIndex) {
                return checked;
            }
            // Jika pertanyaan penyakit bawaan, cek validasi tambahan
            if (currentQuestion === specialDiseaseIndex) {
                if (!checked) return false;
                const value = $("input[name='answer']:checked").val();
                if (value === 'Ya') {
                    const detail = $('#diseaseDetail').val();
                    return detail && detail.trim().length > 0;
                }
                return true;
            }
            // Pertanyaan reguler, harus pilih salah satu
            return checked;
        }
    */
    });
</script> 
<script type="text/disabled">
    // Override start button handler after jQuery and Bootstrap have loaded
    (function() {
        function attachStartHandler() {
            if (typeof window.jQuery !== 'undefined' && typeof bootstrap !== 'undefined') {
                $(function() {
                    // Remove any existing click handlers to avoid duplicates
                    $('#btnStart').off('click').on('click', function (e) {
                        e.preventDefault();
                        // Use showQuestionModal if available
                        if (typeof showQuestionModal === 'function') {
                            showQuestionModal();
                        } else {
                            // Fallback: show the modal manually
                            const modalElement = document.getElementById('questionModal');
                            if (modalElement) {
                                const m = new bootstrap.Modal(modalElement);
                                m.show();
                            }
                        }
                    });
                });
            } else {
                // Retry after a short delay if libraries are not yet loaded
                setTimeout(attachStartHandler, 50);
            }
        }
        attachStartHandler();
    })();
</script>
<script type="text/javascript">
    (function($) {
        $(function() {
            // --------- Global variables ---------
            var selectedUkms = [];
            var recommendedUkms = [];
            var allUkms = [
                { id: 'UKM001', name: 'UKM Olahraga', category: 'olahraga' },
                { id: 'UKM002', name: 'UKM Seni', category: 'seni' },
                { id: 'UKM003', name: 'UKM Kesenian Tradisional', category: 'seni' },
                { id: 'UKM004', name: 'UKM Paduan Suara', category: 'musik' },
                { id: 'UKM005', name: 'UKM Pencak Silat', category: 'beladiri' },
                { id: 'UKM006', name: 'UKM Pramuka', category: 'sosial' },
                { id: 'UKM007', name: 'UKM KSR-PMI', category: 'sosial' },
                { id: 'UKM008', name: 'UKM Koperasi Mahasiswa', category: 'kewirausahaan' },
                { id: 'UKM009', name: 'UKM Jurnalistik', category: 'media' },
                { id: 'UKM010', name: 'UKM Fotografi', category: 'media' },
                { id: 'UKM011', name: 'UKM Robotik', category: 'teknologi' },
                { id: 'UKM012', name: 'UKM Bahasa Asing', category: 'bahasa' },
                { id: 'UKM013', name: 'UKM Debat', category: 'akademik' },
                { id: 'UKM014', name: 'UKM Pecinta Alam', category: 'alam' },
                { id: 'UKM015', name: 'UKM Bola Basket', category: 'olahraga' },
                { id: 'UKM016', name: 'UKM Futsal', category: 'olahraga' },
                { id: 'UKM017', name: 'UKM Badminton', category: 'olahraga' },
                { id: 'UKM018', name: 'UKM Tenis Meja', category: 'olahraga' },
                { id: 'UKM019', name: 'UKM Voli', category: 'olahraga' },
                { id: 'UKM020', name: 'UKM Taekwondo', category: 'beladiri' }
            ];

            // Parse questions from hidden field
            var questions = [];
            var questionsJson = $('#<%= hdnQuestions.ClientID %>').val();
            if (questionsJson) {
                try {
                    questions = JSON.parse(questionsJson);
                } catch (err) {
                    console.error('Error parsing questions JSON:', err);
                }
            }
            // Display error if no questions
            if (!Array.isArray(questions) || questions.length === 0) {
                console.error('No questions found from database.');
                $('#litPesan').html('<div class="alert alert-danger">Pertanyaan tidak dapat dimuat dari database.</div>');
                return;
            }
            // Set total questions text
            $('#totalQuestions').text(questions.length);

            // Index markers for special questions (0-based)
            var specialGenderIndex = 20;
            var specialDiseaseIndex = 21;

            // Answer storage
            var jawabanMahasiswa = {};
            var additionalAnswers = { gender:'', disease:'', diseaseDetail:'' };
            // Likert options (reversed scale)
            var answerOptions = [
                { value: 1, text: 'Sangat Setuju' },
                { value: 2, text: 'Setuju' },
                { value: 3, text: 'Ragu-Ragu' },
                { value: 4, text: 'Tidak Setuju' },
                { value: 5, text: 'Sangat Tidak Setuju' }
            ];

            var currentQuestion = 0;

            // ---------------------------------------------------------------------
            // Custom functions to compute and render UKM recommendations
            //
            // The computeRecommendations function derives a list of recommended UKMs
            // based on the answers stored in jawabanMahasiswa.  A simple scoring
            // mechanism is used: for each answer with a high Likert value (>=4), a
            // category specific score is awarded to the matching UKM categories.  UKMs
            // with a total score of 4 or more are considered recommended.  The
            // renderUkmLists function then builds the HTML for both the recommended
            // and non‑recommended lists, each entry containing a checkbox so the
            // student can select the UKMs they are interested in.  When called,
            // renderUkmLists also resets the selectedUkms array and updates the
            // hidden field hdnSelectedUkms with the currently checked codes.
            function computeRecommendations() {
                recommendedUkms = [];
                allUkms.forEach(function(ukm) {
                    var score = 0;
                    for (var q in jawabanMahasiswa) {
                        var val = parseInt(jawabanMahasiswa[q]);
                        if (val >= 4) {
                            var qi = parseInt(q);
                            if ((ukm.category === 'olahraga' && (qi === 1 || qi === 5 || qi === 9)) ||
                                (ukm.category === 'seni' && (qi === 2 || qi === 6 || qi === 10)) ||
                                (ukm.category === 'sosial' && (qi === 3 || qi === 7 || qi === 11)) ||
                                (ukm.category === 'teknologi' && (qi === 4 || qi === 8 || qi === 12))) {
                                score += 2;
                            }
                        }
                    }
                    if (score >= 4) {
                        recommendedUkms.push(ukm);
                    }
                });
            }

            function renderUkmLists() {
                var recommendedHtml = '';
                var otherHtml = '';
                recommendedUkms.forEach(function(ukm) {
                    recommendedHtml += '<div class="form-check mb-2">' +
                        '<input class="form-check-input ukm-checkbox" type="checkbox" id="ukm_' + ukm.id + '" data-id="' + ukm.id + '" data-name="' + ukm.name + '" data-category="' + ukm.category + '">' +
                        '<label class="form-check-label" for="ukm_' + ukm.id + '">' + ukm.name + '</label>' +
                        '</div>';
                });
                allUkms.forEach(function(ukm) {
                    var isRec = recommendedUkms.some(function(item) { return item.id === ukm.id; });
                    if (!isRec) {
                        otherHtml += '<div class="form-check mb-2">' +
                            '<input class="form-check-input ukm-checkbox" type="checkbox" id="ukm_' + ukm.id + '" data-id="' + ukm.id + '" data-name="' + ukm.name + '" data-category="' + ukm.category + '">' +
                            '<label class="form-check-label" for="ukm_' + ukm.id + '">' + ukm.name + '</label>' +
                            '</div>';
                    }
                });
                $('#recommendedUkmList').html(recommendedHtml || '<p class="text-muted">Tidak ada rekomendasi.</p>');
                $('#otherUkmList').html(otherHtml || '<p class="text-muted">Tidak ada UKM lainnya.</p>');
                // Reset selected codes after rendering lists
                updateSelectedUkms();
            }

            // Render a question by index
            function renderQuestion(index) {
                if (index < 0 || index >= questions.length) {
                    return;
                }
                currentQuestion = index;
                $('#questionNumber').text(index + 1);
                $('#questionText').text(questions[index]);
                var html = '';
                // Gender question
                if (index === specialGenderIndex) {
                    var genderOptions = [
                        { value:'Laki-laki', text:'Laki-laki' },
                        { value:'Perempuan', text:'Perempuan' }
                    ];
                    genderOptions.forEach(function(opt) {
                        var checked = (additionalAnswers.gender === opt.value);
                        html += '<div class="answer-option' + (checked ? ' active' : '') + '" data-value="' + opt.value + '">';
                        html += '<div class="form-check"><input class="form-check-input" type="radio" name="answer" id="gender_' + opt.value + '" value="' + opt.value + '"' + (checked ? ' checked' : '') + '>';
                        html += '<label class="form-check-label" for="gender_' + opt.value + '">' + opt.text + '</label></div></div>';
                    });
                }
                // Disease question
                else if (index === specialDiseaseIndex) {
                    var diseaseOptions = [
                        { value:'Ya', text:'Ya' },
                        { value:'Tidak', text:'Tidak' }
                    ];
                    diseaseOptions.forEach(function(opt) {
                        var checked = (additionalAnswers.disease === opt.value);
                        html += '<div class="answer-option' + (checked ? ' active' : '') + '" data-value="' + opt.value + '">';
                        html += '<div class="form-check"><input class="form-check-input" type="radio" name="answer" id="disease_' + opt.value + '" value="' + opt.value + '"' + (checked ? ' checked' : '') + '>';
                        html += '<label class="form-check-label" for="disease_' + opt.value + '">' + opt.text + '</label></div></div>';
                    });
                    // Text input for disease detail, shown only if answer is 'Ya'
                    var displayStyle = (additionalAnswers.disease === 'Ya') ? 'block' : 'none';
                    var detailValue = additionalAnswers.diseaseDetail || '';
                    html += '<div id="diseaseDetailContainer" style="display: ' + displayStyle + '; margin-top: 1rem;">';
                    html += '<label for="diseaseDetail" class="form-label">Sebutkan penyakit bawaan Anda</label>';
                    html += '<input type="text" class="form-control" id="diseaseDetail" value="' + detailValue + '" placeholder="Masukkan nama penyakit" />';
                    html += '</div>';
                }
                // Regular question
                else {
                    answerOptions.forEach(function(opt) {
                        var answerKey = currentQuestion + 1;
                        var checked = (jawabanMahasiswa[answerKey] === String(opt.value));
                        html += '<div class="answer-option' + (checked ? ' active' : '') + '" data-value="' + opt.value + '">';
                        html += '<div class="form-check"><input class="form-check-input" type="radio" name="answer" id="option' + opt.value + '" value="' + opt.value + '"' + (checked ? ' checked' : '') + '>';
                        html += '<label class="form-check-label" for="option' + opt.value + '">' + opt.text + '</label></div></div>';
                    });
                }
                $('#answerOptions').html(html);
                // Click handler for options
                $('.answer-option').off('click').on('click', function() {
                    var value = $(this).data('value');
                    $('.answer-option').removeClass('active');
                    $(this).addClass('active');
                    $('input[name="answer"]').prop('checked', false);
                    $(this).find('input[type="radio"]').prop('checked', true);
                    // Show/hide disease detail container
                    if (currentQuestion === specialDiseaseIndex) {
                        if (value === 'Ya') {
                            $('#diseaseDetailContainer').show();
                            $('#diseaseDetail').prop('required', true);
                        } else {
                            $('#diseaseDetailContainer').hide();
                            $('#diseaseDetail').prop('required', false).val('');
                        }
                    }
                });
                // Update navigation buttons
                $('#btnPrev').prop('disabled', index === 0);
                $('#btnNext').toggle(index < questions.length - 1);
                $('#btnSubmit').toggle(index === questions.length - 1);
                // Update progress bar
                var progress = Math.round(((index + 1) / questions.length) * 100);
                $('.progress-bar').css('width', progress + '%').attr('aria-valuenow', progress);
            }

            // Save currently selected answer into storage
            function saveCurrentAnswer() {
                var selected = $('input[name="answer"]:checked');
                if (selected.length === 0) {
                    return;
                }
                var value = selected.val();
                if (currentQuestion === specialGenderIndex) {
                    additionalAnswers.gender = value;
                } else if (currentQuestion === specialDiseaseIndex) {
                    additionalAnswers.disease = value;
                    if (value === 'Ya') {
                        additionalAnswers.diseaseDetail = $('#diseaseDetail').val() || '';
                    } else {
                        additionalAnswers.diseaseDetail = '';
                    }
                } else {
                    // Key is 1-based for backend compatibility
                    jawabanMahasiswa[currentQuestion + 1] = value;
                }
            }

            // Validate current answer (checks if selected and, for disease question, detail when needed)
            function validateCurrentAnswer() {
                var selected = $('input[name="answer"]:checked');
                if (currentQuestion === specialGenderIndex) {
                    return selected.length > 0;
                }
                if (currentQuestion === specialDiseaseIndex) {
                    if (selected.length === 0) {
                        return false;
                    }
                    var value = selected.val();
                    if (value === 'Ya') {
                        var detail = $('#diseaseDetail').val();
                        return detail && detail.trim().length > 0;
                    }
                    return true;
                }
                return selected.length > 0;
            }

            // Handler for navigation buttons
            $('#btnPrev').off('click').on('click', function() {
                saveCurrentAnswer();
                renderQuestion(currentQuestion - 1);
            });
            $('#btnNext').off('click').on('click', function() {
                if (validateCurrentAnswer()) {
                    saveCurrentAnswer();
                    renderQuestion(currentQuestion + 1);
                } else {
                    alert('Silakan pilih jawaban terlebih dahulu.');
                }
            });
            // Submit / finish questionnaire
            $('#btnSubmit').off('click').on('click', function(e) {
                e.preventDefault();
                if (!validateCurrentAnswer()) {
                    alert('Silakan pilih jawaban terlebih dahulu.');
                    return;
                }
                saveCurrentAnswer();
                // Save answers into hidden fields
                $('#<%= hdnAnswers.ClientID %>').val(JSON.stringify(jawabanMahasiswa));
                $('#<%= hdnGender.ClientID %>').val(additionalAnswers.gender);
                $('#<%= hdnPenyakit.ClientID %>').val(additionalAnswers.disease);
                $('#<%= hdnDetailPenyakit.ClientID %>').val(additionalAnswers.diseaseDetail);
                // Show loading indicator
                var submitBtn = $(this);
                submitBtn.prop('disabled', true).html('<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Memproses...');
                // Hide modal
                var modalEl = document.getElementById('questionModal');
                var modalInstance = bootstrap.Modal.getInstance(modalEl);
                if (modalInstance) {
                    modalInstance.hide();
                } else {
                    $(modalEl).removeClass('show').css('display', 'none');
                    $('.modal-backdrop').remove();
                    $('body').removeClass('modal-open');
                }
                // Inform user
                $('#litPesan').html('<div class="alert alert-info">Sedang memproses rekomendasi UKM...</div>');
                // Trigger hidden button to process answers after slight delay
                setTimeout(function() {
                    $('#<%= btnProcessAnswers.ClientID %>').trigger('click');
                }, 500);
                // Setelah memulai proses penyimpanan jawaban di server, hitung rekomendasi secara
                // client-side dan tampilkan halaman pemilihan UKM.  Ini memungkinkan
                // mahasiswa untuk langsung memilih UKM tanpa menunggu respon server.
                computeRecommendations();
                renderUkmLists();
                // Sembunyikan tampilan kuesioner dan penyakit, tampilkan pemilihan UKM
                $('#test-tab-pane').hide();
                $('#diseaseSection').hide();
                $('#startCard').hide();
                $('#ukmSection').show();
                $('#biodataSection').hide();
                // Atur status navigasi tab: aktifkan tab UKM dan nonaktifkan biodata
                $('#ukm-tab').prop('disabled', false);
                $('#biodata-tab').prop('disabled', false);
                $('#test-tab').removeClass('active');
                $('#ukm-tab').addClass('active');
                $('#biodata-tab').removeClass('active');
            });

            // Handler for additional navigation (next to results, back to test, next to biodata, back to UKM)
            $('#btnNextToResults').off('click').on('click', function() {
                var penyakitBawaan = $('#<%= txtPenyakitBawaan.ClientID %>').val();
                $('#<%= hdnPenyakitBawaan.ClientID %>').val(penyakitBawaan);
                // Hitung rekomendasi dan render list
                computeRecommendations();
                renderUkmLists();
                // Sembunyikan kuesioner dan bagian penyakit, tampilkan pemilihan UKM
                $('#test-tab-pane').hide();
                $('#diseaseSection').hide();
                $('#startCard').hide();
                $('#ukmSection').show();
                $('#biodataSection').hide();
                // Perbarui status tab navigasi
                $('#ukm-tab').prop('disabled', false);
                $('#biodata-tab').prop('disabled', false);
                $('#test-tab').removeClass('active');
                $('#ukm-tab').addClass('active');
                $('#biodata-tab').removeClass('active');
            });
            $('#btnBackToTest').off('click').on('click', function() {
                // Tampilkan kembali kuesioner (tab tes) dan sembunyikan pemilihan UKM serta biodata
                $('#test-tab-pane').show();
                $('#startCard').show();
                $('#ukmSection').hide();
                $('#biodataSection').hide();
                // Perbarui status tab navigasi
                $('#test-tab').addClass('active');
                $('#ukm-tab').removeClass('active');
                $('#biodata-tab').removeClass('active');
            });
            $('#btnNextToBiodata').off('click').on('click', function() {
                if (selectedUkms.length === 0) {
                    alert('Silakan pilih minimal satu UKM terlebih dahulu.');
                    return;
                }
                // Tampilkan biodata dan sembunyikan pemilihan UKM
                $('#ukmSection').hide();
                $('#biodataSection').show().removeClass('fade').addClass('show active');
                // Aktifkan tab biodata di navigasi
                $('#biodata-tab').prop('disabled', false);
                $('#ukm-tab').removeClass('active');
                $('#biodata-tab').addClass('active');
                $('#test-tab').removeClass('active');
            });
            $('#btnBackToUkm').off('click').on('click', function() {
                // Kembali ke pemilihan UKM dari form biodata
                $('#ukmSection').show();
                $('#biodataSection').hide().removeClass('show active').addClass('fade');
                // Perbarui status tab navigasi
                $('#ukm-tab').addClass('active');
                $('#biodata-tab').removeClass('active');
                $('#test-tab').removeClass('active');
            });
            // Checkbox change for UKM selection
            $(document).off('change.ukmCheckbox').on('change.ukmCheckbox', '.ukm-checkbox', function() {
                updateSelectedUkms();
            });

            // Start button shows modal and first question
            $('#btnStart').off('click').on('click', function(e) {
                e.preventDefault();
                renderQuestion(0);
                // Show modal manually
                var modalEl2 = document.getElementById('questionModal');
                var m = new bootstrap.Modal(modalEl2);
                m.show();
                // Hide start card
                $('#startCard').hide();
            });

            // Helper to update selected UKMs from checkboxes
            function updateSelectedUkms() {
                selectedUkms = [];
                $('.ukm-checkbox:checked').each(function() {
                    var id = $(this).data('id');
                    var name = $(this).data('name');
                    var category = $(this).data('category');
                    selectedUkms.push({ id: id, name: name, category: category });
                });
                // Store only the comma‑separated list of UKM codes in hidden field
                var codes = selectedUkms.map(function(u) { return u.id; });
                $('#<%= hdnSelectedUkms.ClientID %>').val(codes.join(','));
            }

            // Expose showQuestion function for debug if needed
            window.showQuestion = renderQuestion;
        });
    })(jQuery);
    
    // Function to toggle visibility of non-recommended UKMs
    function toggleOtherUkms() {
        const otherUkmsCard = document.getElementById('otherUkmsCard');
        const btnShowOtherUkms = document.getElementById('btnShowOtherUkms');
        
        if (otherUkmsCard && btnShowOtherUkms) {
            if (otherUkmsCard.style.display === 'none' || otherUkmsCard.style.display === '') {
                // Show the card
                otherUkmsCard.style.display = 'block';
                btnShowOtherUkms.innerHTML = '<i class="fas fa-eye-slash me-1"></i>Sembunyikan UKM Lainnya';
                btnShowOtherUkms.classList.remove('btn-outline-primary');
                btnShowOtherUkms.classList.add('btn-outline-secondary');
                
                // Scroll to the other UKMs section
                setTimeout(function() {
                    otherUkmsCard.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }, 100);
            } else {
                // Hide the card
                otherUkmsCard.style.display = 'none';
                btnShowOtherUkms.innerHTML = '<i class="fas fa-list me-1"></i>Lihat UKM Lainnya';
                btnShowOtherUkms.classList.remove('btn-outline-secondary');
                btnShowOtherUkms.classList.add('btn-outline-primary');
            }
            
            // Re-initialize checkbox handlers for the newly shown UKMs
            if (typeof $ !== 'undefined') {
                $('.ukm-checkbox').off('change.otherUkm').on('change.otherUkm', function() {
                    if (typeof updateSelectedUkms === 'function') {
                        updateSelectedUkms();
                    }
                });
            }
        }
    }
    
    // Function to submit UKM selection and navigate to biodata
    function submitUkmSelection() {
        // Get all selected UKMs
        const selectedUkms = [];
        const checkboxes = document.querySelectorAll('.ukm-checkbox:checked');
        
        checkboxes.forEach(function(checkbox) {
            selectedUkms.push(checkbox.value);
        });
        
        if (selectedUkms.length === 0) {
            alert('Silakan pilih minimal satu UKM sebelum melanjutkan.');
            return;
        }
        
        // Store selected UKMs in hidden field
        const hdnSelectedUkms = document.getElementById('<%= hdnSelectedUkms.ClientID %>');
        if (hdnSelectedUkms) {
            hdnSelectedUkms.value = selectedUkms.join(',');
        }
        
        // Show loading state
        const submitBtn = document.getElementById('btnSubmitUkmSelection');
        if (submitBtn) {
            submitBtn.disabled = true;
            submitBtn.innerHTML = '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Menyimpan...';
        }
        
        // Trigger server-side save
        if (typeof __doPostBack === 'function') {
            __doPostBack('<%= btnSubmitPilihanUkm.UniqueID %>', '');
        } else {
            // Fallback: trigger button click
            const serverBtn = document.getElementById('<%= btnSubmitPilihanUkm.ClientID %>');
            if (serverBtn) {
                serverBtn.click();
            }
        }
    }
    
    // Function to show success modal after UKM submission
    function showUkmSuccessModal() {
        var successModal = new bootstrap.Modal(document.getElementById('successModal'), {
            backdrop: 'static',
            keyboard: false
        });
        successModal.show();
    }
    
    // Handle OK button click in success modal
    $(document).ready(function() {
        $('#btnOkSuccess').click(function() {
            // Hide the modal
            $('#successModal').modal('hide');
            
            // Switch to biodata tab after modal closes
            setTimeout(function() {
                // Switch to biodata tab and show it as active
                $('#ukm-tab').removeClass('active');
                $('#biodata-tab').addClass('active').prop('disabled', false);
                $('#ukmSection').hide();
                $('#biodataSection').show().removeClass('fade').addClass('show active').css('display', 'block');
                
                // Scroll to top
                $('html, body').animate({ scrollTop: 0 }, 500);
                
                // Debug: Log that biodata section should be visible
                console.log('Biodata section should now be visible');
                console.log('Biodata section display:', $('#biodataSection').css('display'));
            }, 300);
        });
    });
</script>