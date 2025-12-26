shader_type canvas_item;

// sampler2d input to load correct texture - name:  custom_texture
uniform sampler2D custom_texture;
uniform int cooldown_progress : hint_range(0, 100) = 100;
uniform vec4 active_color : source_color = vec4(0.2, 0.7, 0.2, 1.0);  // Border color
uniform vec4 cooldown_color : source_color = vec4(0.7, 0.2, 0.2, 1.0);  // Border color ON cooldown
//uniform vec4 active_color : source_color = vec4(0.0, 0.6, 1.0, 1.0);  // Blue-ish
//uniform vec4 cooldown_color : source_color = vec4(1.0, 0.6, 0.0, 1.0);  // Orange-ish
uniform float border : hint_range (0.0, 0.5) = 0.05;
void fragment() {
    vec2 uv = UV;
    float progress = float(cooldown_progress) / 100.0;
    
    // Check if we are drawing the Border or the Center
    bool is_border = (uv.x < border || uv.x > 1.0 - border || uv.y < border || uv.y > 1.0 - border);
    
    if (is_border) {
        // --- RECTANGULAR PERIMETER LOGIC ---
        // We calculate "how far along the edge" this pixel is (0.0 to 4.0)
        float dist = 0.0;
        
        if (uv.y < border) { 
            // Top Edge (0.0 to 1.0)
            dist = uv.x;
        } else if (uv.x > 1.0 - border) { 
            // Right Edge (1.0 to 2.0)
            dist = 1.0 + uv.y;
        } else if (uv.y > 1.0 - border) { 
            // Bottom Edge (2.0 to 3.0) - traversing right to left
            dist = 2.0 + (1.0 - uv.x);
        } else { 
            // Left Edge (3.0 to 4.0) - traversing bottom to top
            dist = 3.0 + (1.0 - uv.y);
        }
        
        // Normalize distance to 0.0 - 1.0
        float perimeter_pos = dist / 4.0;
        
        // Color based on progress
        if (perimeter_pos > progress) {
            COLOR = cooldown_color; // Not reached yet (Red)
        } else {
            COLOR = active_color;   // Filled (Green)
        }
    } 
    else 
    {
        // --- ICON LOGIC (Vertical Wipe) ---
        // Instead of just "Blinking", we fill the icon from Bottom to Top
        // This usually looks better with a square border.
        
        vec4 tex_color = texture(custom_texture, uv);
        
        // "1.0 - uv.y" gives us height from bottom (0 at bottom, 1 at top)
        if (1.0 - uv.y > progress) {
            // Darken/Grayscale the part that is waiting
            float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
            tex_color.rgb = vec3(gray) * 0.5; 
        }
        
        COLOR = tex_color;
    }
}