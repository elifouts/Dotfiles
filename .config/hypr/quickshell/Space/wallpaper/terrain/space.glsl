    // launch and orbit
    if (rise > 0.0) {
        vec3 space = mix(vec3(0.015, 0.02, 0.05), zenith.rgb * 0.4, 0.3);
        float sp2 = smoothstep(0.22, 0.5, rise);
        col = mix(col, space, sp2);
        col *= 1.0 - sp2 * clear;
        float t = clamp((rise - 0.45) / 0.55, 0.0, 1.0), p = t * t * (2.65 - 1.65 * t);
        float R = exp(mix(log(3.5), log(endR), p));
        vec2 pc = vec2(0.0, mix(mix(0.06, 0.5 + endR, p) - R, 0.5, smoothstep(0.45, 0.9, p)));
        vec2 d = vec2(x, y0) - pc;
        float rr = length(d) / R;
        float show = smoothstep(0.45, 0.52, rise) * orbit;
        vec3 L = normalize(sun.xyz);

        float aa = fwidth(rr) * 1.2;

        vec2 md = vec2(x, y0) - mc;
        float mr = length(md) / mR, maa = fwidth(mr) * 1.2;
        vec3 mn = vec3(md / mR, sqrt(max(0.0, 1.0 - mr * mr)));
        float mpx = fwidth(mr);
        vec3 mL = normalize(mix(skyL, L, mq));
        float mfull = smoothstep(0.04, 0.55, rise), mo = 1.0;
        vec3 mcol = vec3(0.0);
        if (mr < 1.05) {
            float k = skyFace(mn, mL, mpx, mfull);
            mo = mix(k, 1.0, mfull);
            mcol = mix(moon.rgb * k, light(moonSurf(mn, mL, mpx, mfull), mn, mL, 0.0), mfull) / mo;
        }
        float mshape = smoothstep(1.0 + maa, 1.0 - maa, mr);
        vec3 mglow = vec3(0.0);
        if (A > 0.0) {
            float mk = smoothstep(0.4, 0.58, rise);
            vec2 aq = md / (mR * atlasSize);
            vec4 at = atlasShape(aq - vec2(0.0, 0.14), maa / atlasSize, mL);
            vec4 mm = marker(aq - vec2(0.0, 0.14 * (1.0 - mk)), maa / atlasSize, mk);
            mcol = mix(mcol, mix(atlasCol(at, maa), mm.rgb, mk), A);
            mo = mix(mo, mix(mix(0.6, 1.0, mfull), 1.0, mk), A);
            mshape = mix(mshape, mix(at.y, mm.a, mk), A);
            mglow = mix(horizon.rgb, warm.rgb, 0.35) * mix(at.w * 0.22 + exp(-length(aq * 0.31 - vec2(0.0, 0.0434)) * 7.0) * 0.12, exp(-max(length(md / (mR * atlasSize)) - 0.75, 0.0) * 9.0) * (1.0 - mm.a) * 0.25, mk) * atlasGlow * A;
        }
        float mcov = mshape * step(0.5, moonEnd.w) * orbit * (1.0 - cover);
        mglow *= step(0.5, moonEnd.w) * orbit * (1.0 - cover);
        float ma = mcov * mo;
        float front = step(1.5, moonEnd.w);
        float skyOp = rise > 0.2 ? min(1.0, rise * 1.5) : 0.0;
        vec3 stars = view.w > 0.5 ? skyStars(qt_TexCoord0 + vec2(0.0, 0.36 * max(0.0, 0.22 - rise))) * morph * (1.0 - mcov) * (1.0 - cover) * mix(smoothstep(0.38, 0.78, y0 + r2 * 0.15), 1.0, sp2) : vec3(0.0);

        if (rr > 1.6 || show <= 0.0) {
            float a0 = mix(1.0, mcov, sp2 * clear);
            fragColor = vec4((mix(col, mcol, ma) + mglow + dither()) * a0 + stars * (1.0 - (1.0 - a0) * skyOp), a0) * qt_Opacity;
            return;
        }
        float ball = smoothstep(1.0 + aa, 1.0 - aa, rr) * show;
        vec3 n = vec3(d / R, sqrt(max(0.0, 1.0 - rr * rr)));
        float px = aa / 1.2;
        vec3 surf;
        float ahalo = 0.0;
        if (kind > 0.5 && atlas > 0.0) {
            vec4 mm = marker(d / R, aa, 1.0);
            surf = mix(light(moonSurf(n, L, px, 1.0), n, L, 0.0), mm.rgb, atlas);
            ball = mix(ball, mm.a * show, atlas);
            ahalo = exp(-max(length(d / R) - 0.75, 0.0) * 9.0) * (1.0 - mm.a) * 0.2 * atlasGlow * atlas * show;
        }
        else if (kind > 0.5) surf = light(moonSurf(n, L, px, 1.0), n, L, 0.0);
        else {
            vec4 ps = planetSurf(n, px);
            float spec = pow(max(dot(reflect(-L, n), vec3(0.0, 0.0, 1.0)), 0.0), 24.0) * ps.a * step(rr, 1.0);
            surf = light(ps.rgb, n, L, 1.0) + mix(warm.rgb, vec3(1.0), 0.5) * spec * 0.35;
        }
        vec3 body = mix(col, mcol, ma * (1.0 - front));
        body = mix(body, surf, ball);
        body = mix(body, mcol, ma * front);
        vec2 dn = d / max(length(d), 1e-4);
        float halo = 0.5 * step(kind, 0.5) * exp(-max(rr - 1.0, 0.0) * 22.0) * step(1.0, rr) * show * smoothstep(-0.4, 0.5, dot(dn, L.xy));
        body += mix(horizon.rgb, warm.rgb, 0.4) * halo + mix(horizon.rgb, warm.rgb, 0.35) * ahalo * 1.5 + mglow;
        float a = mix(1.0, clamp(ball + halo + ahalo + mcov, 0.0, 1.0), sp2 * clear);
        fragColor = vec4((body + dither()) * a + stars * (1.0 - ball) * (1.0 - (1.0 - a) * skyOp), a) * qt_Opacity;
        return;
    }
