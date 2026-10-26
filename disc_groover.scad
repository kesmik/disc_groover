
/*
 Kids phonograph Optical Disc Generator
 White layer with barcode cutouts. Black backing with raised inserts.

 Decimal ID:
 - Cut through BLACK layer only
 - Mirrored for reading from black side

 10-bit binary encoding:
 Narrow = 1
 Wide = 0

 All dimensions in millimeters.
*/

/* PARAMETERS */
disc_id = 1;

/* final part appearance. Possible variants: assembled, exploded, white, black, side_by_side */
part = "assembled";

/* layer thicknesses */
white_t = 0.30;
black_t = 0.30;

/* disc diameter */
disc_d = 70;

/* black disc settings */
fit_clearance = 0.15;
use_raised_inserts = false;


/* center lock */
main_hole_d = 10;
lobe_d = 5;
lock_span = 14;
lobe_angle = 90;

/* barcode */
barcode_length = 15.5;
edge_margin = 0.7;

wide_width = 12;
narrow_width = 5;

/* separate corner radius */
wide_corner_radius = 3.1;
narrow_corner_radius = 1.5;

/* decimal ID cutout */
show_id = true;
id_font_size = 6;
id_y = -12;
id_digit_spacing = 5;
id_bridge = 0.4;

/* Circle resolution */
$fn = 120;


/* CALCULATED PARAMETERS */
lobe_offset = (lock_span - lobe_d) / 2;

outer_r = disc_d / 2 - edge_margin;

inner_r = outer_r - barcode_length;

/* 10 stripes + 1 empty position */
pitch = 360 / 11;


/* center lock */
module keyed_hole() {

    union() {

        circle(d = main_hole_d);

        for (angle = [
            lobe_angle,
            lobe_angle + 180
        ]) {

            translate([
                lobe_offset * cos(angle),
                lobe_offset * sin(angle)
            ])

            circle(d = lobe_d);
        }
    }
}


/* disc draw with center lock */
module disc_outline() {

    difference() {

        circle(d = disc_d);

        keyed_hole();
    }
}


function get_bit(value, i) =
    floor(value / pow(2, i)) % 2;


module raw_barcode_wedge(i) {

    bit = get_bit(disc_id, i);

    w = bit == 1
        ? narrow_width
        : wide_width;

    polygon(points = [

        [inner_r, -w / 2],

        [outer_r, -w / 2],

        [outer_r, w / 2],

        [inner_r, w / 2]

    ]);
}


/* Rounded barcode stripe.
    Different corner radii for wide and narrow.
    Shrink only affects black inserts.
*/

module barcode_stripe(i, shrink = 0) {

    bit = get_bit(disc_id, i);

    r = bit == 1
        ? narrow_corner_radius
        : wide_corner_radius;

    rotate(i * pitch)

    offset(delta = -shrink)

    offset(r = r)

    offset(delta = -r)

    raw_barcode_wedge(i);
}


module decimal_id_cutout() {

    if (show_id) {

        label = str(disc_id);

        /* Mirror text so it reads correctly when viewing the black underside. */
        translate([0, id_y])

        mirror([1, 0, 0])

        for (i = [0 : len(label) - 1]) {

            translate([
                (i - (len(label) - 1) / 2)
                    * id_digit_spacing,
                0
            ])

            difference() {

                text(
                    label[i],
                    size = id_font_size,
                    font = "Liberation Sans:style=Bold",
                    halign = "center",
                    valign = "center"
                );

                /* Small bridge keeps enclosed parts of digits connected. */
                square(
                    [id_bridge, id_font_size + 2],
                    center = true
                );
            }
        }
    }
}


/* generate white disc */
module white_disc(z = 0) {

    color([0.97, 0.97, 0.96])

    translate([0, 0, z])

    linear_extrude(height = white_t)

    difference() {

        disc_outline();

        /* Barcode holes */
        for (i = [0:9]) {
            barcode_stripe(i);
        }
    }
}


/* generate black disc */
module black_disc() {

    color([0.10, 0.11, 0.12])

    difference() {

        union() {

            linear_extrude(height = black_t)
                disc_outline();
            
            /* Raised barcode inserts */
            if (use_raised_inserts == true) {
                translate([0, 0, black_t])
                linear_extrude(height = white_t)

                for (i = [0:9]) {
                    barcode_stripe(
                        i,
                        fit_clearance
                    );
                }
            }
        }

        /* Cut mirrored decimal number through BLACK backing only. */
        translate([0, 0, -0.01])

        linear_extrude(
            height = black_t + 0.02
        )

        decimal_id_cutout();
    }
}


module validate() {

    assert(
        disc_id >= 0 &&
        disc_id <= 1023 &&
        disc_id == floor(disc_id),
        "Invalid disc ID"
    )

    assert(
        disc_d > 0 &&
        barcode_length > 0 &&
        inner_r > 0 &&
        outer_r < disc_d / 2,
        "Invalid disc dimensions"
    )

    assert(
        lock_span >= main_hole_d &&
        lock_span >= lobe_d,
        "Invalid center lock"
    )

    assert(
        white_t > 0 &&
        black_t > 0 &&
        fit_clearance >= 0,
        "Invalid thickness or tolerance"
    )

    assert(
        wide_width > 0 &&
        narrow_width > 0 &&
        wide_corner_radius >= 0 &&
        narrow_corner_radius >= 0,
        "Invalid stripe dimensions"
    )

    assert(
        id_font_size > 0 &&
        id_digit_spacing > 0 &&
        id_bridge >= 0 &&
        id_bridge < id_font_size,
        "Invalid decimal ID dimensions"
    )

    children();
}


module model() {

    validate() {

        if (part == "white") {

            white_disc();

        }
        else if (part == "black") {

            black_disc();

        }
        else if (part == "exploded") {

            black_disc();

            white_disc(black_t + 2);

        }
        else if (part == "side_by_side") {

            translate([
                -disc_d / 2 - 4,
                0,
                0
            ])
                black_disc();

            translate([
                disc_d / 2 + 4,
                0,
                0
            ])
                white_disc();

        }
        else {

            black_disc();

            white_disc(black_t);
        }
    }
}

model();
