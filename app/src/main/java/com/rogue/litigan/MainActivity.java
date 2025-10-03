package com.rogue.litigan;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // A super simple "Hello World" layout
        android.widget.TextView tv = new android.widget.TextView(this);
        tv.setText("Hello from Rogue Litigan!");
        setContentView(tv);
    }
}
