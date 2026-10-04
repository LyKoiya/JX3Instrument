
#文本添加尾部字符
function Add-TrailingCharacter {
    param(
        [string]$InputText,
        [string]$Character
    )

    if ($InputText.EndsWith($Character)) {
        return $InputText
    }
    return $InputText + $Character
}

#表格文件转曲谱
function csv2xlsx_PS {
    param(
        [Parameter(Mandatory=$true)]
        [string]$filePath
    )

    #创建Excel的COM对象
    $excel = New-Object -ComObject Ket.Application

    if (-not $excel) {
        $excel = New-Object -ComObject Excel.Application
        if (-not $excel) {
            Write-Error "无法创建Excel COM对象，请确保已安装Excel。"
            return
        }
    }
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    $workbook = $excel.Workbooks.Open($filePath)
    $sheet = $workbook.Sheets.Item(1)

    #写入公式
    $last = $sheet.UsedRange.Rows.Count + 1
    $range = $sheet.Range("E2:E$last")
    $range.Formula = '=IF(ISBLANK(B2),IF(ISBLANK(B1),"","}"),"["&B2&"]={szState1="""&C2&""","&"szKey1="""&D2&"""},")'

    $range = $sheet.Range("F2:F$last")
    $range.Formula = '=IF(ISBLANK(D2),"","Delay "&IFERROR(B2-B1,B2)&CHAR(10)&"Key"&C2&" """&D2&""", 1")'

    #保存文件
    $newPath = [System.IO.Path]::GetFileNameWithoutExtension($filePath)
    $newPath = Join-Path -Path (Split-Path $filePath) -ChildPath $newPath
    $newPath = Add-TrailingCharacter -InputText $newPath -Character ".xlsx"
    $workbook.SaveAS($newPath, 61)

    # 释放资源
    $workbook.Close($false)
    $excel.Quit()
    [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($excel) | Out-Null


}

csv2xlsx_PS -filePath $args[0]
exit
