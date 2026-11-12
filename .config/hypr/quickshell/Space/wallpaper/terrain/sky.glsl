    // sky
    col = mix(horizon.rgb, zenith.rgb, smoothstep(0.16, 0.9, y));
    col += warm.rgb * dusk * exp(-length(vec2(x * 0.55, (y - 0.27) * 2.4)) * 3.0);
    col = mix(col, mix(warm.rgb, horizon.rgb, 0.3), glow * 0.55 * smoothstep(0.75, 0.15, y));
    col += warm.rgb * glow * 0.6 * exp(-length(vec2((x - pan * 0.02 - 0.25) * 0.8, (y - 0.27) * 2.2)) * 2.5);

    // moon
    vec2 md = vec2(x - pan * 0.02 + lift * 0.35, y - 0.56 - lift);
    float mr = length(md);
    float disc = smoothstep(0.31 + fwidth(mr), 0.31 - fwidth(mr), mr) * (1.0 - moonless);
    float handed = rise > 0.0 ? step(0.5, moonEnd.w) : 0.0;
    float face = 0.0, mpx = fwidth(mr) / 0.31;
    if (mr < 0.32 && moonless < 0.5 && handed < 0.5 && A < 1.0) face = skyFace(vec3(md / 0.31, sqrt(max(0.0, 1.0 - dot(md, md) / 0.0961))), skyL, mpx, 0.0);
    col = mix(col, mix(col, mix(moon.rgb, warm.rgb * 1.1, glow * 0.75), face + max(smoothstep(0.0, 0.3, abs(lift)), glow) * 0.5), disc * (1.0 - handed) * (1.0 - A));
    float acov = 0.0;
    // atlas
    if (A > 0.0) {
        vec4 at = atlasShape(md / (0.31 * atlasSize) - vec2(0.0, 0.14), mpx * 1.2 / atlasSize, skyL);
        acov = at.y * (1.0 - handed);
        vec3 hot = mix(horizon.rgb, warm.rgb, 0.35);
        col = mix(col, mix(col, atlasCol(at, mpx), 0.6 + glow * 0.2), acov * A);
        col += hot * (at.w * 0.22 + exp(-length(md / atlasSize - vec2(0.0, 0.0434)) * 7.0) * 0.12) * atlasGlow * A * (1.0 - handed) * skyFade;
    }
    disc = mix(disc, acov, A);

    vec2 cq = (vec2(x, y0) - mc) / (mR * atlasSize) - vec2(0.0, 0.14);
    float cut = mix(disc, step(0.5, moonEnd.w) * orbit * mix(smoothstep(1.03, 0.97, length(vec2(x, y0) - mc) / mR), smoothstep(1.03, 0.97, abs(cq.x) / 0.54 + abs(cq.y) / atlasKy(cq.y)), A), handed);
    float skyMask = smoothstep(0.38, 0.78, y) * (1.0 - cut) * skyFade * (1.0 - morph) * (1.0 - glow * 0.6);
    float gI = 0.0;
    // galaxy
    float GL = galaxy * clamp(1.0 + wv(9.0) * 0.6, 0.0, 1.6);
    if (GL > 0.0 && y > 0.34) {
        float ga = galaxyTilt + wv(7.0) * 0.9, ca = cos(ga), sa = sin(ga);
        vec2 gp = vec2(x + pan * 0.05 / 12.0 - wv(8.0) * aspect * 0.25, y - 0.7);
        float u = ca * gp.x + sa * gp.y, v = -sa * gp.x + ca * gp.y;
        float wd = 0.075 * (1.0 + 0.5 * n1(u * 2.3 + 40.0));
        float body = exp(-v * v / (wd * wd)) * (0.4 + 0.6 * exp(-u * u * 1.5));
        float dust = smoothstep(0.42, 0.75, fbm2(vec2(u * 14.0, v * 40.0) + 7.0)) * exp(-pow((v - 0.012 * sin(u * 5.0)) / (wd * 0.35), 2.0));
        gI = body * (0.35 + 0.65 * fbm2(vec2(u * 9.0, v * 26.0))) * (1.0 - 0.4 * dust) * GL;
        vec3 gcol = mix(mix(horizon.rgb, moon.rgb, 0.5), warm.rgb, exp(-u * u * 3.0) * 0.6);
        col += gcol * gI * 0.32 * skyMask;

        // --- milky way star field ---
        // density follows the band, clumps via noise, thins out in dust lanes
        float clump = smoothstep(0.30, 0.80, fbm2(vec2(u * 11.0, v * 34.0) + 21.0));
        float sd    = body * (1.0 - 0.7 * dust);
        float dens  = clamp(sd * (0.25 + 1.1 * clump), 0.0, 1.0) * 0.55;

        vec2 sp = vec2(u, v);
        float st = starLayer(sp,               260.0, dens)
                + starLayer(sp + 0.37,        420.0, dens * 0.9) * 0.7
                + starLayer(sp + 0.71,        650.0, dens * 0.8) * 0.5;

        vec3 stCol = mix(vec3(0.80, 0.90, 1.00), warm.rgb, exp(-u * u * 3.0) * 0.5);
        col += stCol * st * 0.55 * GL * skyMask;
    }
    // stars
    vec2 g = vec2(x * 12.0 + pan * 0.05, y * 12.0);
    vec2 cell = floor(g), f = fract(g) - 0.5;
    float pOn = (0.45 + moonless * 0.14) * starAmt * clamp(1.0 + wv(10.0) * 0.4, 0.0, 2.0) + gI * 0.3;
    float starOn = step(1.0 - clamp(pOn, 0.0, 0.95), h2(cell));
    vec2 p = f - (vec2(h2(cell + 3.1), h2(cell + 7.7)) - 0.5) * 0.7;
    float size = mix(0.007, 0.028, pow(h2(cell + 1.3), 2.0)) * starSize * mix(1.0, 0.35, morph);
    float starDot = exp(-3.2 * dot(p, p) / (size * size)) * starOn;
    col += starDot * (0.8 + 0.2 * h2(cell + 9.9)) * 1.05 * skyMask;
    // comet
    float cW = aspect * 0.5 - 0.06, cB = cW - 0.36, cu0 = h1(5.0);
    for (int i = 0; i < 6; i++) {
        float on = clamp(comet - float(i), 0.0, 1.0);
        if (on <= 0.0) break;
        float ck = float(i) * 17.0;
        float cu = fract(cu0 + (i == 1 ? 0.5 : i == 2 ? 0.25 : i == 3 ? 0.75 : i == 4 ? 0.125 : i == 5 ? 0.625 : 0.0) + (h1(ck + 5.0) - 0.5) * 0.06) * 2.0 * cB;
        vec2 s0 = vec2(cu < cB ? cu - cW : cu - cW + 0.72, (i < 2 ? 0.8 : i < 4 ? 0.68 : 0.94) + (h1(ck + 6.0) - 0.5) * 0.05);
        vec2 dir = normalize(vec2(1.0, 0.28));
        float cl = 1.0, cw = 0.0015, cb = 0.7;
        if (i > 0) {
            dir = vec2(h1(ck + 9.0) < 0.5 ? -1.0 : 1.0, (h1(ck + 7.0) - 0.5) * 0.9);
            cl = 0.6 + 1.2 * h1(ck + 8.0);
            cw = 0.0009 + 0.0016 * h1(ck + 10.0);
            cb = 0.45 + 0.4 * h1(ck + 11.0);
            dir = normalize(dir);
        }
        s0 -= dir * 0.05 * cl;
        vec2 sp = vec2(x + pan * 0.05 / 12.0, y) - s0;
        float along = dot(sp, dir) / cl, off = abs(dot(sp, vec2(-dir.y, dir.x)));
        col += (1.0 - smoothstep(0.0, cw, off)) * smoothstep(0.0, 0.08, along) * (1.0 - smoothstep(0.06, 0.1, along))
             * smoothstep(0.38, 0.78, y) * (1.0 - cut) * cb * skyFade * (1.0 - morph) * on;
    }

    // flying ships
    float sxw = x + pan * 0.3;
    float sc = floor(sxw / 3.5 + 0.5);
    vec2 sp0 = vec2(sxw - (sc * 3.5 + (h1(sc + 7.0) - 0.5) * 1.6), y - (0.5 + 0.25 * h1(sc + 13.0)));
    float sa = (h1(sc + 19.0) - 0.5) * 0.4, scs = cos(sa), sns = sin(sa);
    vec2 sq = vec2(scs * sp0.x + sns * sp0.y, -sns * sp0.x + scs * sp0.y);
    float fly = step(h1(sc + 23.0), fleet) * traffic * skyFade;
    float skyShip = shipShape(sq, 0.07 + 0.03 * h1(sc + 29.0), fwidth(y), 0.0) * fly;
    float behind = -sq.x - 0.02;
    float tw = max(0.0018, fwidth(y) * 1.5);
    float trail = (1.0 - smoothstep(0.0, tw, abs(sq.y))) * smoothstep(-0.004, 0.0, behind) * (1.0 - smoothstep(0.0, 0.3, behind));
    col += warm.rgb * trail * 0.8 * fly;
    col = mix(col, mix(near.rgb, horizon.rgb, 0.18), skyShip);
    cover = skyShip;
