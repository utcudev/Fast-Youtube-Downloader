@{
    # Bu betik kullaniciyla konusan etkilesimli bir konsol aracidir;
    # renkli ciktinin karsiligi Write-Host'tur. Kural modul/pipeline
    # senaryolari icin tasarlanmis, burada gecerli degil.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost'
    )
}
