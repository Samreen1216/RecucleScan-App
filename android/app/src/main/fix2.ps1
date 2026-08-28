$files = @("res/layout/widget_compact.xml", "res/layout/widget_wide.xml", "res/layout/widget_large.xml")
foreach ($file in $files) {
    $content = Get-Content $file -Raw
    $pattern = '(?s)<LinearLayout\s+android:id="@\+id/btn_next_view".*?</LinearLayout>'
    $replacement = @"
    <LinearLayout
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_gravity="bottom|end"
        android:layout_margin="8dp"
        android:orientation="horizontal">
        <LinearLayout
            android:id="@+id/btn_prev_view"
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:background="@drawable/widget_chip_bg"
            android:gravity="center"
            android:layout_marginRight="8dp">
            <TextView android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="?" android:textColor="#1B5E20" android:textSize="12sp" android:textStyle="bold" />
        </LinearLayout>
        <LinearLayout
            android:id="@+id/btn_next_view"
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:background="@drawable/widget_chip_bg"
            android:gravity="center">
            <TextView android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="?" android:textColor="#1B5E20" android:textSize="12sp" android:textStyle="bold" />
        </LinearLayout>
    </LinearLayout>
"@
    $content = $content -replace $pattern, $replacement
    $content | Set-Content $file -Encoding UTF8
}
Write-Host "Replaced!"
