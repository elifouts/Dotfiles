    // mountains
    y = y0 + r2 * 0.35;
    float xp = x * 1.6 + pan * 0.06;
    float peaks = mountH(xp, R, H);
    float pk = under(y, peaks);
    vec3 pc0 = mix(far.rgb, horizon.rgb, mix(0.5, 0.85, HZ));
    float sy = y - (0.27 + 0.13 * H * (1.25 - 0.5 * SN)) + 0.012 * n1(xp * 18.0), saa = fwidth(y);
    pc0 = mix(pc0, mix(pc0, moon.rgb, 0.3), smoothstep(0.4, 0.85, R) * smoothstep(-saa, saa, sy) * step(0.001, SN));
    col = mix(col, pc0, pk);
    cover = max(cover, pk);
    // far astronaut
    {
        vec3 pk3 = peakAt(0.0, xp, y, peaks, 1.6, 4.6, 0.0, 0.0115, 0.0, 0.0, 0.0, R, H, 85.0);
        if (pk3.z > 0.0) {
            float ac, fsx = (pk3.x - pan * 0.06) / 1.6, face = mc.x < fsx ? -1.0 : 1.0;
            col = astroPaint(col, pc0 * 0.86, vec2((xp - pk3.x) / 1.6 * face + 0.0004, y - pk3.y + 0.0002) / 0.0115, saa / 0.0115, 2.0, 0.0, 0.15, ac);
            cover = max(cover, ac);
        }
    }

    // ridges
    for (int i = 0; i < 3; i++) {
        float k = float(i) / 2.0;
        y = y0 + r2 * (0.45 + k * 0.2);
        float xs = 2.0 - k * 0.6;
        float xx = x * xs + pan * (0.12 + k * 0.25);
        float m = R * (1.0 - k * 0.5);
        float h = ridgeH(xx, k, float(i) * 3.0, m, H);
        float hcx = 0.0, hg = 0.0, hon = 0.0;
        // base pad
        if (i == 2 && BS > 0.0) {
            float hc = floor(xx / 2.6);
            hcx = (hc + 0.5 + (h1(hc + 51.0) - 0.5) * 0.5) * 2.6;
            hon = step(h1(hc + 53.0), BS);
            hg = ridgeH(hcx, k, float(i) * 3.0, m, H);
            h = mix(h, hg, hon * smoothstep(0.42, 0.3, abs(xx - hcx) / xs));
        }
        vec3 lc = mix(far.rgb, horizon.rgb, (1.0 - k) * mix(0.2, 0.8, HZ)) * (0.9 + 0.15 * smoothstep(h - 0.12, h, y));
        float rg = under(y, h);
        col = mix(col, lc, rg);
        col = mix(col, horizon.rgb, HZ * 0.3 * (1.0 - k) * rg * smoothstep(h - 0.02, h - 0.14, y));
        cover = max(cover, rg);
        col = mix(col, mix(horizon.rgb, warm.rgb, glow * 0.6), 0.12 * exp(-abs(y - h + 0.01) * 60.0) * (1.0 - k));
        // habitat
        if (i == 2 && BS > 0.0) {
            float flip = h1(hcx + 57.0) < 0.5 ? -1.0 : 1.0;
            vec2 hb = habitat(vec2((xx - hcx) / xs * flip, y - hg) / 1.5, fwidth(y) / 1.5, hcx) * hon;
            col = mix(col, lc * 0.9, hb.x);
            col += mix(warm.rgb, vec3(1.0), 0.25) * min(hb.y, 1.5) * 0.85;
            cover = max(cover, hb.x);
            if (hon > 0.0 && abs(xx - hcx) / xs < 0.36) {
                float hship = step(h1(hcx + 58.0), 0.4) * ship, cs = h1(hcx + 59.0) < 0.5 ? -1.0 : 1.0;
                // base camp
                vec3 hsz = habSize(hcx);
                vec3 cp = camp(1.0, xx, y, xs, hcx, hg, 0.42, 0.3, cs, 1.0 - hship, step(0.2, h1(hcx + 60.0)) * (0.35 + 0.45 * h1(hcx + 61.0)), 0.07 + hsz.x * 1.5 + hsz.y * 0.035 + step(0.5, hsz.z) * 0.04, 0.011, hcx, k, 6.0, m, R, H, fwidth(y), 1.0, 2.0 + hsz.z);
                col = mix(col, lc * mix(0.85, 0.95, cp.z), cp.x);
                col += mix(warm.rgb, vec3(1.0), 0.25) * cp.y * 0.6;
                cover = max(cover, cp.x);
                float ce = 0.07 + hsz.x * 1.5 + hsz.y * 0.035 + step(0.5, hsz.z) * 0.04 + 0.1;
                float rk = max(pebbles(xx / xs, y, h, hcx / xs + cs * ce, 0.03, 0.003, hcx * 3.0 + 1.0, fwidth(y)), pebbles(xx / xs, y, h, hcx / xs - cs * (ce + 0.03), 0.03, 0.003, hcx * 3.0 + 7.0, fwidth(y)));
                col = mix(col, lc, rk);
                cover = max(cover, rk);
                // parked ship
                if (hship > 0.0) {
                    vec4 sp = shipLanded(vec2((xx - hcx + cs * (0.12 + hsz.x * 1.5 + hsz.y * 0.035 + step(0.5, hsz.z) * 0.04) * xs) / xs * (h1(hcx + 62.0) < 0.5 ? -1.0 : 1.0), y - hg), 0.045, fwidth(y));
                    col = mix(col, lc * mix(0.85, 0.97, smoothstep(-0.08, 0.08, sp.y)), sp.x);
                    col += mix(warm.rgb, horizon.rgb, 0.3) * (sp.z * 0.5 + sp.w * 0.2);
                    cover = max(cover, sp.x);
                }
            }
        }
        // ridge trees
        if (i == 2) {
            float tr = max(max(trees(xx, y, h, 0.3 * F, 50.0, 0.5 * treeSize, xs, hcx, hon * 0.36, vec3(1.0, R, H)), grass(xx, y, h, min(0.12 * G, 0.9), 55.0)), rockBed(xx / xs, y, h, RK, 0.3, 0.005, 140.0, hcx / xs, hon * 0.3, fwidth(y)));
            col = mix(col, lc, tr);
            cover = max(cover, tr);
        }
    }

    // main hill
    y = y0 + r2 * 0.95;
    float xm = x + pan * 0.6;
    float c5 = floor(xm / 2.5);
    float gcx = c5 * 2.5 + 1.25 + (h1(c5 + 31.0) - 0.5) * 1.1;
    float here = step(h1(c5 + 37.0), ships) * ship;
    float padH = max(hillRaw(gcx, R, H), 0.19);
    float dx = xm - gcx;
    float hill = mix(hillRaw(xm, R, H), padH, here * smoothstep(0.42, 0.16, abs(dx)));
    vec3 hillCol = near.rgb + warm.rgb * (0.07 + glow * 0.2) * exp(-max(hill - y, 0.0) * 90.0) * smoothstep(1.2, 0.0, abs(x));
    hillCol += warm.rgb * 0.14 * here * exp(-abs(dx) * 7.0) * exp(-abs(y - padH) * 70.0);
    float groundShip = 0.0;
    // landed ship
    if (ship > 0.0) {
        float flip = h1(c5 + 41.0) < 0.5 ? -1.0 : 1.0, ss = 0.1 + 0.04 * h1(c5 + 43.0);
        vec4 sp = shipLanded(vec2(dx * flip, y - padH), ss, fwidth(y)) * here;
        groundShip = sp.x;
        col = mix(col, mix(near.rgb * 1.1, mix(near.rgb, far.rgb, 0.55), smoothstep(-0.08, 0.08, sp.y)), groundShip);
        col += mix(warm.rgb, horizon.rgb, 0.3) * sp.z * 0.6 + mix(warm.rgb, vec3(1.0), 0.2) * sp.w * 0.25;
    }
    // hill trees
    float exr = step(0.5, here) * 0.38;
    float scrub = grass(xm, y, hill, min(0.12 * G, 0.9) * mix(1.0, step(0.3, abs(dx)), here), 30.0);
    float lx = clamp((mc.x - x) * 1.5, -1.0, 1.0);
    float caa = fwidth(y);
    float hrk = max(rockBed(xm, y, hill, RK, 0.6, 0.013, 120.0, gcx, here * 0.5, caa), here > 0.0 ? max(pebbles(xm, y, hill, gcx + 0.24, 0.035, 0.0045, c5 * 7.0 + 1.0, caa), pebbles(xm, y, hill, gcx - 0.25, 0.035, 0.0045, c5 * 7.0 + 9.0, caa)) : 0.0);
    float hc = max(max(under(y, hill), hrk), max(trees(xm, y, hill, 0.55 * F, 0.0, treeSize, 1.0, gcx, exr, vec3(0.0)), scrub));
    col = mix(col, hillCol, hc);
    cover = max(cover, max(hc, groundShip));
    // ship camp
    if (here > 0.0 && abs(dx) < 0.26) {
        vec3 cp = camp(2.0, xm, y, 1.0, gcx, padH, 0.42, 0.16, h1(c5 + 63.0) < 0.5 ? -1.0 : 1.0, 1.0, step(0.25, h1(c5 + 61.0)) * (0.3 + 0.7 * h1(c5 + 62.0)), 0.075, 0.009, c5, 0.0, 0.0, 0.0, R, H, caa, 0.0, 3.0);
        col = mix(col, mix(near.rgb * 1.1, mix(near.rgb, far.rgb, 0.45), cp.z), cp.x);
        col += mix(warm.rgb, vec3(1.0), 0.25) * cp.y * 0.7;
        cover = max(cover, cp.x);
    }
    // near astronaut
    if (tvM == 1.0 || tvM == 2.0) {
        float bc = floor(xm / 5.0), ax0, face, ok;
        if (tvM == 1.0) {
            ax0 = (bc + 0.3 + 0.4 * h1(bc + 91.0)) * 5.0;
            face = h1(bc + 92.0) < 0.5 ? -1.0 : 1.0;
            ok = (1.0 - here * step(abs(ax0 - gcx), 0.5));
        } else {
            float fl = h1(c5 + 41.0) < 0.5 ? -1.0 : 1.0;
            ax0 = gcx + fl * (0.175 + 0.015 * h1(c5 + 94.0));
            face = -fl;
            ok = here * step(mod(c5, 2.0), 0.5) * step(h1(c5 + 95.0), 0.7);
        }
        if (ok > 0.0 && abs(xm - ax0) < 0.12) {
            float ag = tvM == 2.0 ? mix(hillRaw(ax0, R, H), padH, smoothstep(0.42, 0.16, abs(ax0 - gcx))) : hillRaw(ax0, R, H), ac;
            // scan
            if (tvM == 1.0) {
                float bx0 = ax0 + face * 0.065, bgh = hillRaw(bx0, R, H), ps = 0.022;
                vec2 bp = vec2((xm - bx0) / ps, (y - bgh) / ps + 0.05);
                float pd = smin(lump(bp, vec2(0.0, 0.45), vec2(1.2, 0.6), bc), sdBox(bp - vec2(0.0, 0.15), vec2(0.85, 0.2), 0.0), 0.15);
                float pcv = smoothstep(caa / ps, -caa / ps, pd);
                vec3 accent = mix(mix(horizon.rgb, warm.rgb, 0.5), vec3(1.0), 0.15);
                vec2 tip = vec2(ax0 + face * 0.42 * 0.036, ag + 0.645 * 0.036), tc0 = vec2(bx0, bgh + ps * 0.5);
                vec2 dir = normalize(tc0 - tip), pq = vec2(xm, y) - tip;
                float along = dot(pq, dir), reach = length(tc0 - tip), across = abs(dir.x * pq.y - dir.y * pq.x);
                float spread = along / reach * ps * 0.7, inside = step(0.0, along) * smoothstep(spread + caa, spread - caa, across);
                float fade = smoothstep(0.0, reach * 0.3, along) * smoothstep(reach * 1.08, reach * 0.9, along) * smoothstep(hill - 0.001, hill + 0.002, y);
                float edges = exp(-abs(across - spread) / (caa * 1.2)) * step(0.0, along) * fade;
                col += accent * (inside * 0.1 + edges * 0.25) * fade;
                col = mix(col, near.rgb + accent * 0.14 * smoothstep(0.0, 1.0, bp.y) * step(0.0, along), pcv);
                col += accent * 0.18 * exp(-max(pd, 0.0) * 20.0) * (1.0 - pcv);
                cover = max(cover, pcv);
                float rk = pebbles(xm, y, hill, bx0 + face * 0.04, 0.018, 0.0035, bc * 5.0 + 3.0, caa);
                col = mix(col, hillCol, rk);
                cover = max(cover, rk);
            }
            // crate seat
            if (tvM == 2.0) {
                vec2 bq = vec2((xm - ax0) * face, y - ag) / 0.036;
                float bcv = smoothstep(caa / 0.036, -caa / 0.036, sdBox(bq - vec2(-0.03, 0.15), vec2(0.17, 0.19), 0.02));
                col = mix(col, mix(near.rgb * 1.1, mix(near.rgb, far.rgb, 0.45), smoothstep(0.0, 0.34, bq.y)), bcv);
                cover = max(cover, bcv);
            }
            col = astroPaint(col, mix(near.rgb, far.rgb, 0.08), vec2((xm - ax0) * face, y - ag + 0.0008) / 0.036, caa / 0.036, tvM == 1.0 ? 1.0 : 4.0, lx, 1.0, ac);
            cover = max(cover, ac);
        }
    }

    // foreground
    y = y0 + r2 * 1.5;
    float fx = x * 0.7 + pan * 1.1;
    float fg = 0.09 + roll(fx, 21.0) * 0.04 * H - x * 0.02;
    float fc = max(max(under(y, fg), rockBed(fx, y, fg, RK, 1.4, 0.025, 160.0, 0.0, 0.0, fwidth(y))), max(trees(fx, y, fg, 0.14 * F, 70.0, 1.5 * treeSize, 0.7, 0.0, 0.0, vec3(0.0)), grass(fx, y, fg, min(0.14 * G, 0.9), 75.0)));
    col = mix(col, near.rgb * (0.68 + 0.12 * smoothstep(fg - 0.08, fg, y)), fc);
    cover = max(cover, fc);
