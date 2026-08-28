import re

new_btns = """    <LinearLayout
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
                android:text="&lt;" android:textColor="#1B5E20" android:textSize="14sp" android:textStyle="bold" />
        </LinearLayout>
        <LinearLayout
            android:id="@+id/btn_next_view"
            android:layout_width="32dp"
            android:layout_height="32dp"
            android:background="@drawable/widget_chip_bg"
            android:gravity="center">
            <TextView android:layout_width="wrap_content" android:layout_height="wrap_content"
                android:text="&gt;" android:textColor="#1B5E20" android:textSize="14sp" android:textStyle="bold" />
        </LinearLayout>
    </LinearLayout>
</FrameLayout>"""

files = ['res/layout/widget_compact.xml', 'res/layout/widget_wide.xml', 'res/layout/widget_large.xml']
for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
    content = re.sub(r'<LinearLayout[^>]*android:layout_gravity="bottom\|end"[^>]*>.*?</LinearLayout>\s*</FrameLayout>', new_btns, content, flags=re.DOTALL)
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)

print('Fixed')
