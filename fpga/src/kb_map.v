// ============================================================================
// kb_map - traduce las pulsaciones de un teclado con una distribución dada a
// la matriz del teclado japonés, que es la que espera la BIOS.
//
// La entrada `map` selecciona la distribución de ORIGEN:
//
//     0  el teclado ya es japonés, no hay traducción (keys_jis = keys)
//     1  internacional -> japonés
//     2  brasileño (Gradiente Expert) -> japonés
//     3  brasileño (Sharp Hotbit HB-8000) -> japonés
//     4  francés AZERTY (Philips VG-8020F) -> japonés
//     5  Philips VG-8000 y VG-8010 (matriz de prototipo) -> japonés
//     6  español -> japonés
//
// Cada mapa es un módulo aparte que produce la matriz japonesa completa en
// keys_jis[0:15]. Añadir un mapa es escribir su módulo, instanciarlo aquí y
// meter una línea más en el multiplexor. Llevan puerto `kana` los mapas cuyo
// teclado tiene la fila de dígitos como el internacional (el propio y el del
// VG-8000); en los demás la tecla CODE sigue pasando sin tocar, así que el
// juego extendido funciona igual, solo que con otros caracteres.
//
// Convenio de la matriz MSX: bit a 0 = tecla pulsada.
// `shift` es el bit de la matriz (activo a nivel bajo); `kana` es el estado
// que envía el nivel superior (activo a nivel alto).
// ============================================================================

module kb_map(
	input wire [7:0] keys [0:15],
    input wire kana,
	input wire [2:0] map,
	output wire [7:0] keys_jis [0:15]

);

    localparam MAP_JIS  = 3'd0;     // sin traducción
    localparam MAP_INTL = 3'd1;     // internacional -> japonés
    localparam MAP_BR   = 3'd2;     // brasileño (Gradiente) -> japonés
    localparam MAP_SHARP = 3'd3;    // brasileño (Sharp Hotbit) -> japonés
    localparam MAP_FR   = 3'd4;     // francés AZERTY (VG-8020F) -> japonés
    localparam MAP_VG   = 3'd5;     // Philips VG-8000 / VG-8010 -> japonés
    localparam MAP_ES   = 3'd6;     // español -> japonés

    wire [7:0] m_intl  [0:15];
    wire [7:0] m_br    [0:15];
    wire [7:0] m_sharp [0:15];
    wire [7:0] m_fr    [0:15];
    wire [7:0] m_vg    [0:15];
    wire [7:0] m_es    [0:15];

    kb_map_intl u_map_intl (
        .keys       (keys),
        .kana       (kana),
        .keys_jis   (m_intl)
    );

    kb_map_br u_map_br (
        .keys       (keys),
        .keys_jis   (m_br)
    );

    kb_map_sharp u_map_sharp (
        .keys       (keys),
        .keys_jis   (m_sharp)
    );

    kb_map_fr u_map_fr (
        .keys       (keys),
        .keys_jis   (m_fr)
    );

    kb_map_vg u_map_vg (
        .keys       (keys),
        .kana       (kana),
        .keys_jis   (m_vg)
    );

    kb_map_es u_map_es (
        .keys       (keys),
        .kana       (kana),
        .keys_jis   (m_es)
    );

// ---------------------------------------------------------------- selección
//
// El caso por defecto es no traducir, así que un `map` sin mapa asociado deja
// pasar la matriz tal cual.

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : map_mux
            assign keys_jis [i] = ( map == MAP_INTL )  ? m_intl [i]  :
                                  ( map == MAP_BR )    ? m_br [i]    :
                                  ( map == MAP_SHARP ) ? m_sharp [i] :
                                  ( map == MAP_FR )    ? m_fr [i]    :
                                  ( map == MAP_VG )    ? m_vg [i]    :
                                  ( map == MAP_ES )    ? m_es [i]    :
                                                         keys [i];
        end
    endgenerate

endmodule


// ============================================================================
// kb_map_intl - teclado internacional -> matriz del teclado japonés
//
//         B7  B6  B5  B4  B3  B2  B1  B0        origen (internacional)
//  Row0_S  &   ^   %   $   #   @   !   )
//  Row0    7   6   5   4   3   2   1   0
//  Row1_S  :   }   {   |   +   _   (   *
//  Row1    ;   ]   [   \   =   -   9   8
//  Row2_S  B   A   .   ?   >   <   ~   "
//  Row2    b   a   .   /   .   ,   `   ´
//
// Row2/B5 no se usa: lleva £ en unas máquinas y acentos muertos en otras, y
// ninguno de los dos existe en el juego de caracteres japonés.
// ============================================================================

module kb_map_intl(
    input  wire [7:0] keys [0:15],
    input  wire       kana,
    output wire [7:0] keys_jis [0:15]
);

    //characters
    wire num0;
    wire num1;
    wire num2;
    wire num3;
    wire num4;
    wire num5;
    wire num6;
    wire num7;
    wire num8;
    wire num9;
    wire amper;     //&
    wire caret;     //^
    wire percent;   //%
    wire dollar;    //$
    wire hash;      //#
    wire at;        //@
    wire excl;      //!
    wire rparen;    //)
    wire colon;     //:
    wire semi;      //;
    wire rbrace;    //}
    wire rbracket;  //]
    wire lbrace;    //{
    wire lbracket;  //[
    wire pipe;      //|
    wire bslash;    //\
    wire plus;      //+
    wire equal;     //=
    wire under;     //_
    wire minus;     //-
    wire lparen;    //(
    wire star;      //*
    wire quest;     //?
    wire slash;     ///
    wire greater;   //>
    wire dot;       //.
    wire less;      //<
    wire comma;     //,
    wire tilde;     //~
    wire backtick;  //`
    wire dquote;    //"
    //wire squote;    //' //doesn't exists in msx
    wire acute;     //´
    wire a;
    wire b;
    wire shift;


    assign shift =  keys [6][0];

    //  &   ^   %   $   #   @   !   )
    //  7   6   5   4   3   2   1   0
    assign num7 =   (~shift & ~kana) | keys [0][7];
    assign amper =  shift | kana | keys [0][7];

    assign num6 =   (~shift & ~kana)| keys [0][6];
    assign caret =  shift | kana | keys [0][6];

    assign num5 =   ~shift | keys [0][5];
    assign percent = shift | keys [0][5];

    assign num4 =   ~shift | keys [0][4];
    assign dollar = shift | keys [0][4];

    assign num3 = ~shift | keys [0][3];
    assign hash = shift | keys [0][3];

    assign num2 = ~shift | keys [0][2];
    assign at = shift | keys [0][2];

    assign num1 = ~shift | keys [0][1];
    assign excl = shift | keys [0][1];

    assign num0 = (~shift & ~kana) | keys [0][0];
    assign rparen = shift | kana | keys [0][0];

    //  :   }   {   |   +   _   (   *
    //  ;   ]   [   \   =   -   9   8
    assign semi = ~shift | keys [1][7];
    assign colon = shift | keys [1][7];

    assign rbracket = ~shift | keys [1][6];
    assign rbrace = shift | keys [1][6];

    assign lbracket = ~shift | keys [1][5];
    assign lbrace = shift | keys [1][5];

    assign bslash = ~shift | keys [1][4];
    assign pipe = shift | keys [1][4];

    assign equal = ~shift | kana | keys [1][3]; //kanji disabled, same as minus
    assign plus =  shift | kana | keys [1][3]; //kanji disabled, same as semi

    assign minus = ~shift | keys [1][2];
    assign under = shift | keys [1][2];

    assign num9 = (~shift & ~kana) | keys [1][1];
    assign lparen = shift | kana | keys [1][1];

    assign num8 = (~shift & ~kana) | keys [1][0];
    assign star = shift | kana | keys [1][0];

    //  B   A       ?   >   <   ~   "
    //  b   a       /   .   ,   `   ´
    assign b = keys [2][7];
    assign a = keys [2][6];
    //assign acute = keys [2][5];

    assign slash = ~shift | keys [2][4];
    assign quest = shift | keys [2][4];

    assign dot = ~shift | keys [2][3];
    assign greater = shift | keys [2][3];

    assign comma = ~shift | keys [2][2];
    assign less = shift | keys [2][2];

    assign backtick = ~shift | keys [2][1];
    assign tilde = shift | keys [2][1];

    assign acute = ~shift | keys [2][0];
    assign dquote = shift | keys [2][0];

    wire invert_shift;

    //jis keys
    wire key_num7_acute;
    wire key_num6_amper;
    wire key_num5_percent;
    wire key_num4_dollar;
    wire key_num3_hash;
    wire key_num2_dquote;
    wire key_num1_excl;
    wire key_num0;

    wire key_semi_plus;
    wire key_lbracket_lbrace;
    wire key_at_backtick;
    wire key_yen_pipe;
    wire key_caret_tilde;
    wire key_minus_equal;
    wire key_num9_rparen;
    wire key_num8_lparen;

    wire key_b;
    wire key_a;
    wire key_under;
    wire key_slash_quest;
    wire key_dot_greater;
    wire key_comma_less;
    wire key_rbracket_rbrace;
    wire key_colon_star;


    wire jis_shift;
    assign invert_shift = ~caret | ~at | ~backtick | ~acute | ~colon | ~equal;
    assign jis_shift = shift ^ invert_shift;

    assign key_num7_acute = ( jis_shift == 1  || kana == 1) ? num7 : acute;
    assign key_num6_amper = ( jis_shift == 1 || kana == 1) ? num6 : amper;
    assign key_num5_percent = ( jis_shift == 1 ) ? num5 : percent;
    assign key_num4_dollar = ( jis_shift == 1 ) ? num4 : dollar;
    assign key_num3_hash = ( jis_shift == 1 ) ? num3 : hash;
    assign key_num2_dquote = ( jis_shift == 1 ) ? num2 : dquote;
    assign key_num1_excl = ( jis_shift == 1 ) ? num1 : excl;
    assign key_num0 = num0;

    assign key_semi_plus = ( jis_shift == 1 ) ? semi : plus;
    assign key_lbracket_lbrace = ( jis_shift == 1 ) ? lbracket : lbrace;
    assign key_at_backtick = ( jis_shift == 1 ) ? at : backtick;
    assign key_yen_pipe = ( jis_shift == 1 ) ? bslash : pipe;
    assign key_caret_tilde = ( jis_shift == 1 ) ? caret : tilde;
    assign key_minus_equal = ( jis_shift == 1 ) ? minus : equal;
    assign key_num9_rparen = ( jis_shift == 1 || kana == 1 ) ? num9 : rparen;
    assign key_num8_lparen = ( jis_shift == 1 || kana == 1 ) ? num8 : lparen;

    assign key_b = b;
    assign key_a = a;
    assign key_under = under;
    assign key_slash_quest = ( jis_shift == 1 ) ? slash : quest;
    assign key_dot_greater = ( jis_shift == 1 ) ? dot : greater;
    assign key_comma_less = ( jis_shift == 1 ) ? comma : less;
    assign key_rbracket_rbrace = ( jis_shift == 1 ) ? rbracket : rbrace;
    assign key_colon_star = ( jis_shift == 1 ) ? colon : star;


    assign keys_jis [0] = { key_num7_acute, key_num6_amper, key_num5_percent, key_num4_dollar, key_num3_hash, key_num2_dquote, key_num1_excl, key_num0 };
    assign keys_jis [1] = { key_semi_plus, key_lbracket_lbrace, key_at_backtick, key_yen_pipe, key_caret_tilde, key_minus_equal, key_num9_rparen, key_num8_lparen };
    assign keys_jis [2] = { key_b, key_a, key_under, key_slash_quest, key_dot_greater, key_comma_less, key_rbracket_rbrace, key_colon_star };
    assign keys_jis [3:5] = keys [3:5];
    assign keys_jis [6] = { keys[6][7:1], jis_shift };
    assign keys_jis [7:15] = keys [7:15];

endmodule


// ============================================================================
// kb_map_br - teclado brasileño (Gradiente Expert) -> matriz del teclado japonés
//
//         B7  B6  B5  B4  B3  B2  B1  B0        origen (Gradiente)
//  Row0_S  &   ^   %   $   #   "   !   )
//  Row0    7   6   5   4   3   2   1   0
//  Row1_S  ^   ]   `   }   +   _   (   ´      <- B7 y B5 son teclas muertas
//  Row1    ~   [   ´   {   =   -   9   8
//  Row2_S  B   A   ?   :   >   <   |   @      <- B1 era Ç
//  Row2    b   a   /   ;   .   ,   \   *      <- B1 era ç
//
// Row1/B7 y Row1/B5 son teclas muertas en el Gradiente: no emiten código, la
// BIOS las compone con la tecla siguiente. Aquí se mapean al acento que llevan
// impreso, de modo que el teclado alcanza el juego japonés completo. Eso hace
// que ´ y ^ se puedan teclear por dos sitios, lo cual no estorba.
//
// Row2/B1 llevaba ç y Ç, que no existen en el juego de caracteres japonés. Se
// reaprovecha para \ y | (esta con shift), que el Gradiente no puede teclear de
// ninguna otra forma.
//
// Este mapa no usa kana, así que el puerto no está.
// ============================================================================

module kb_map_br(
    input  wire [7:0] keys [0:15],
    output wire [7:0] keys_jis [0:15]
);

    //characters
    wire num0;
    wire num1;
    wire num2;
    wire num3;
    wire num4;
    wire num5;
    wire num6;
    wire num7;
    wire num8;
    wire num9;
    wire amper;     //&
    wire caret;     //^
    wire percent;   //%
    wire dollar;    //$
    wire hash;      //#
    wire at;        //@
    wire excl;      //!
    wire rparen;    //)
    wire colon;     //:
    wire semi;      //;
    wire rbrace;    //}
    wire rbracket;  //]
    wire lbrace;    //{
    wire lbracket;  //[
    wire pipe;      //|
    wire bslash;    //\
    wire plus;      //+
    wire equal;     //=
    wire under;     //_
    wire minus;     //-
    wire lparen;    //(
    wire star;      //*
    wire quest;     //?
    wire slash;     ///
    wire greater;   //>
    wire dot;       //.
    wire less;      //<
    wire comma;     //,
    wire dquote;    //"
    wire acute;     //´
    wire a;
    wire b;
    wire shift;

    // Las cuatro teclas muertas. No emiten código en el Gradiente, pero llevan
    // impreso el acento, así que se mapean al carácter que les corresponde.
    // dk_acute va aparte de `acute` porque el mismo carácter llega desde dos
    // teclas con nivel de shift distinto y no pueden compartir cable.
    wire dk_tilde;  //~ Row1/B7 sin shift
    wire dk_caret;  //^ Row1/B7 con shift
    wire dk_acute;  //´ Row1/B5 sin shift
    wire dk_grave;  //` Row1/B5 con shift


    assign shift =  keys [6][0];

    //  &   ^   %   $   #   "   !   )
    //  7   6   5   4   3   2   1   0
    assign num7 =   ~shift | keys [0][7];
    assign amper =  shift | keys [0][7];

    assign num6 =   ~shift | keys [0][6];
    assign caret =  shift | keys [0][6];

    assign num5 =   ~shift | keys [0][5];
    assign percent = shift | keys [0][5];

    assign num4 =   ~shift | keys [0][4];
    assign dollar = shift | keys [0][4];

    assign num3 = ~shift | keys [0][3];
    assign hash = shift | keys [0][3];

    assign num2 = ~shift | keys [0][2];
    assign dquote = shift | keys [0][2];

    assign num1 = ~shift | keys [0][1];
    assign excl = shift | keys [0][1];

    assign num0 = ~shift | keys [0][0];
    assign rparen = shift | keys [0][0];

    //  ^   ]   `   }   +   _   (   ´
    //  ~   [   ´   {   =   -   9   8
    assign dk_tilde = ~shift | keys [1][7];
    assign dk_caret = shift | keys [1][7];

    assign dk_acute = ~shift | keys [1][5];
    assign dk_grave = shift | keys [1][5];

    assign lbracket = ~shift | keys [1][6];
    assign rbracket = shift | keys [1][6];

    assign lbrace = ~shift | keys [1][4];
    assign rbrace = shift | keys [1][4];

    assign equal = ~shift | keys [1][3];
    assign plus =  shift | keys [1][3];

    assign minus = ~shift | keys [1][2];
    assign under = shift | keys [1][2];

    assign num9 = ~shift | keys [1][1];
    assign lparen = shift | keys [1][1];

    assign num8 = ~shift | keys [1][0];
    assign acute = shift | keys [1][0];

    //  B   A   ?   :   >   <   |   @
    //  b   a   /   ;   .   ,   \   *
    assign b = keys [2][7];
    assign a = keys [2][6];

    assign slash = ~shift | keys [2][5];
    assign quest = shift | keys [2][5];

    assign semi = ~shift | keys [2][4];
    assign colon = shift | keys [2][4];

    assign dot = ~shift | keys [2][3];
    assign greater = shift | keys [2][3];

    assign comma = ~shift | keys [2][2];
    assign less = shift | keys [2][2];

    assign bslash = ~shift | keys [2][1];   // la tecla que llevaba ç
    assign pipe = shift | keys [2][1];      // la tecla que llevaba Ç

    assign star = ~shift | keys [2][0];
    assign at = shift | keys [2][0];

    wire invert_shift;

    //jis keys
    wire key_num7_acute;
    wire key_num6_amper;
    wire key_num5_percent;
    wire key_num4_dollar;
    wire key_num3_hash;
    wire key_num2_dquote;
    wire key_num1_excl;
    wire key_num0;

    wire key_semi_plus;
    wire key_lbracket_lbrace;
    wire key_at_backtick;
    wire key_yen_pipe;
    wire key_caret_tilde;
    wire key_minus_equal;
    wire key_num9_rparen;
    wire key_num8_lparen;

    wire key_b;
    wire key_a;
    wire key_under;
    wire key_slash_quest;
    wire key_dot_greater;
    wire key_comma_less;
    wire key_rbracket_rbrace;
    wire key_colon_star;


    wire jis_shift;

    // Caracteres que en el JIS viven en el nivel de shift contrario al que
    // ocupan en el Gradiente.
    assign invert_shift = ~caret | ~rbracket | ~lbrace | ~equal | ~colon | ~star | ~at
                        | ~dk_tilde | ~dk_caret | ~dk_acute;
    assign jis_shift = shift ^ invert_shift;

    // acute y dk_acute caen en la misma ranura; se combinan con AND porque los
    // cables de carácter son activos a nivel bajo.
    assign key_num7_acute = ( jis_shift == 1 ) ? num7 : (acute & dk_acute);
    assign key_num6_amper = ( jis_shift == 1 ) ? num6 : amper;
    assign key_num5_percent = ( jis_shift == 1 ) ? num5 : percent;
    assign key_num4_dollar = ( jis_shift == 1 ) ? num4 : dollar;
    assign key_num3_hash = ( jis_shift == 1 ) ? num3 : hash;
    assign key_num2_dquote = ( jis_shift == 1 ) ? num2 : dquote;
    assign key_num1_excl = ( jis_shift == 1 ) ? num1 : excl;
    assign key_num0 = ( jis_shift == 1 ) ? num0 : 1'b1;     // el JIS no da shift+0

    assign key_semi_plus = ( jis_shift == 1 ) ? semi : plus;
    assign key_lbracket_lbrace = ( jis_shift == 1 ) ? lbracket : lbrace;
    assign key_at_backtick = ( jis_shift == 1 ) ? at : dk_grave;
    assign key_yen_pipe = ( jis_shift == 1 ) ? bslash : pipe;
    assign key_caret_tilde = ( jis_shift == 1 ) ? (caret & dk_caret) : dk_tilde;
    assign key_minus_equal = ( jis_shift == 1 ) ? minus : equal;
    assign key_num9_rparen = ( jis_shift == 1 ) ? num9 : rparen;
    assign key_num8_lparen = ( jis_shift == 1 ) ? num8 : lparen;

    assign key_b = b;
    assign key_a = a;
    assign key_under = under;
    assign key_slash_quest = ( jis_shift == 1 ) ? slash : quest;
    assign key_dot_greater = ( jis_shift == 1 ) ? dot : greater;
    assign key_comma_less = ( jis_shift == 1 ) ? comma : less;
    assign key_rbracket_rbrace = ( jis_shift == 1 ) ? rbracket : rbrace;
    assign key_colon_star = ( jis_shift == 1 ) ? colon : star;


    assign keys_jis [0] = { key_num7_acute, key_num6_amper, key_num5_percent, key_num4_dollar, key_num3_hash, key_num2_dquote, key_num1_excl, key_num0 };
    assign keys_jis [1] = { key_semi_plus, key_lbracket_lbrace, key_at_backtick, key_yen_pipe, key_caret_tilde, key_minus_equal, key_num9_rparen, key_num8_lparen };
    assign keys_jis [2] = { key_b, key_a, key_under, key_slash_quest, key_dot_greater, key_comma_less, key_rbracket_rbrace, key_colon_star };
    assign keys_jis [3:5] = keys [3:5];
    assign keys_jis [6] = { keys[6][7:1], jis_shift };
    assign keys_jis [7:15] = keys [7:15];

endmodule


// ============================================================================
// kb_map_sharp - teclado brasileño (Sharp Hotbit HB-8000) -> matriz japonesa
//
//         B7  B6  B5  B4  B3  B2  B1  B0        origen (Hotbit)
//  Row0_S  &   "   %   $   #   @   !   )
//  Row0    7   6   5   4   3   2   1   0
//  Row1_S  }   '   `   ^   +   _   (   *      <- B7 era C-cedilla
//  Row1    {   |   '   \   =   -   9   8      <- B7 era c-cedilla
//  Row2_S  B   A   >   ?   :   ;   ]   ^      <- B0 era tecla muerta
//  Row2    b   a   <   /   .   ,   [   ~
//
// El Hotbit no alcanza cinco caracteres del japonés: grave, llave abierta,
// barra vertical, llave cerrada y tilde. Se reparten entre los huecos que
// deja el teclado:
//
//   Row1/B7   llevaba c-cedilla y C-cedilla, que no existen en japonés
//             -> llave abierta y llave cerrada
//   Row1/B6   no tenía función sin shift (con shift ya daba acento agudo)
//             -> barra vertical
//   Row1/B5   tecla muerta agudo / grave       -> agudo y grave
//   Row2/B0   tecla muerta tilde / circunflejo -> tilde y circunflejo
//
// Con eso el Hotbit cubre el juego japonés completo. El acento agudo y el
// circunflejo quedan accesibles por dos teclas, lo cual no estorba.
//
// Este mapa no usa kana, así que el puerto no está.
// ============================================================================

module kb_map_sharp(
    input  wire [7:0] keys [0:15],
    output wire [7:0] keys_jis [0:15]
);

    //characters
    wire num0;
    wire num1;
    wire num2;
    wire num3;
    wire num4;
    wire num5;
    wire num6;
    wire num7;
    wire num8;
    wire num9;
    wire amper;     //&
    wire caret;     //^
    wire percent;   //%
    wire dollar;    //$
    wire hash;      //#
    wire at;        //@
    wire excl;      //!
    wire rparen;    //)
    wire colon;     //:
    wire semi;      //;
    wire rbrace;    //}
    wire rbracket;  //]
    wire lbrace;    //{
    wire lbracket;  //[
    wire pipe;      //|
    wire bslash;    //\
    wire plus;      //+
    wire equal;     //=
    wire under;     //_
    wire minus;     //-
    wire lparen;    //(
    wire star;      //*
    wire quest;     //?
    wire slash;     ///
    wire greater;   //>
    wire dot;       //.
    wire less;      //<
    wire comma;     //,
    wire dquote;    //"
    wire acute;     //acento agudo
    wire a;
    wire b;
    wire shift;

    // Teclas muertas. dk_acute va aparte de `acute`, y dk_caret aparte de
    // `caret`, porque el mismo carácter llega desde dos teclas con nivel de
    // shift distinto y no pueden compartir cable.
    wire dk_acute;  //acento agudo  Row1/B5 sin shift
    wire dk_grave;  //acento grave  Row1/B5 con shift
    wire dk_tilde;  //tilde         Row2/B0 sin shift
    wire dk_caret;  //circunflejo   Row2/B0 con shift


    assign shift =  keys [6][0];

    //  &   "   %   $   #   @   !   )
    //  7   6   5   4   3   2   1   0
    assign num7 =   ~shift | keys [0][7];
    assign amper =  shift | keys [0][7];

    assign num6 =   ~shift | keys [0][6];
    assign dquote = shift | keys [0][6];

    assign num5 =   ~shift | keys [0][5];
    assign percent = shift | keys [0][5];

    assign num4 =   ~shift | keys [0][4];
    assign dollar = shift | keys [0][4];

    assign num3 = ~shift | keys [0][3];
    assign hash = shift | keys [0][3];

    assign num2 = ~shift | keys [0][2];
    assign at = shift | keys [0][2];

    assign num1 = ~shift | keys [0][1];
    assign excl = shift | keys [0][1];

    assign num0 = ~shift | keys [0][0];
    assign rparen = shift | keys [0][0];

    //  }   '   `   ^   +   _   (   *
    //  {   |   '   \   =   -   9   8
    assign lbrace = ~shift | keys [1][7];   // la tecla que llevaba c-cedilla
    assign rbrace = shift | keys [1][7];    // la tecla que llevaba C-cedilla

    assign pipe = ~shift | keys [1][6];     // el hueco que no tenía función
    assign acute = shift | keys [1][6];

    assign dk_acute = ~shift | keys [1][5];
    assign dk_grave = shift | keys [1][5];

    assign bslash = ~shift | keys [1][4];
    assign caret = shift | keys [1][4];

    assign equal = ~shift | keys [1][3];
    assign plus =  shift | keys [1][3];

    assign minus = ~shift | keys [1][2];
    assign under = shift | keys [1][2];

    assign num9 = ~shift | keys [1][1];
    assign lparen = shift | keys [1][1];

    assign num8 = ~shift | keys [1][0];
    assign star = shift | keys [1][0];

    //  B   A   >   ?   :   ;   ]   ^
    //  b   a   <   /   .   ,   [   ~
    assign b = keys [2][7];
    assign a = keys [2][6];

    assign less = ~shift | keys [2][5];
    assign greater = shift | keys [2][5];

    assign slash = ~shift | keys [2][4];
    assign quest = shift | keys [2][4];

    assign dot = ~shift | keys [2][3];
    assign colon = shift | keys [2][3];

    assign comma = ~shift | keys [2][2];
    assign semi = shift | keys [2][2];

    assign lbracket = ~shift | keys [2][1];
    assign rbracket = shift | keys [2][1];

    assign dk_tilde = ~shift | keys [2][0];
    assign dk_caret = shift | keys [2][0];

    wire invert_shift;

    //jis keys
    wire key_num7_acute;
    wire key_num6_amper;
    wire key_num5_percent;
    wire key_num4_dollar;
    wire key_num3_hash;
    wire key_num2_dquote;
    wire key_num1_excl;
    wire key_num0;

    wire key_semi_plus;
    wire key_lbracket_lbrace;
    wire key_at_backtick;
    wire key_yen_pipe;
    wire key_caret_tilde;
    wire key_minus_equal;
    wire key_num9_rparen;
    wire key_num8_lparen;

    wire key_b;
    wire key_a;
    wire key_under;
    wire key_slash_quest;
    wire key_dot_greater;
    wire key_comma_less;
    wire key_rbracket_rbrace;
    wire key_colon_star;


    wire jis_shift;

    // Caracteres que en el japonés viven en el nivel de shift contrario al que
    // ocupan en el Hotbit. Son doce, más que en ningún otro mapa.
    assign invert_shift = ~at | ~lbrace | ~pipe | ~dk_acute | ~caret | ~equal
                        | ~less | ~colon | ~semi | ~rbracket | ~dk_tilde | ~dk_caret;
    assign jis_shift = shift ^ invert_shift;

    // Donde concurren dos orígenes se combinan con AND, porque los cables de
    // carácter son activos a nivel bajo.
    assign key_num7_acute = ( jis_shift == 1 ) ? num7 : (acute & dk_acute);
    assign key_num6_amper = ( jis_shift == 1 ) ? num6 : amper;
    assign key_num5_percent = ( jis_shift == 1 ) ? num5 : percent;
    assign key_num4_dollar = ( jis_shift == 1 ) ? num4 : dollar;
    assign key_num3_hash = ( jis_shift == 1 ) ? num3 : hash;
    assign key_num2_dquote = ( jis_shift == 1 ) ? num2 : dquote;
    assign key_num1_excl = ( jis_shift == 1 ) ? num1 : excl;
    assign key_num0 = ( jis_shift == 1 ) ? num0 : 1'b1;     // el japonés no da shift+0

    assign key_semi_plus = ( jis_shift == 1 ) ? semi : plus;
    assign key_lbracket_lbrace = ( jis_shift == 1 ) ? lbracket : lbrace;
    assign key_at_backtick = ( jis_shift == 1 ) ? at : dk_grave;
    assign key_yen_pipe = ( jis_shift == 1 ) ? bslash : pipe;
    assign key_caret_tilde = ( jis_shift == 1 ) ? (caret & dk_caret) : dk_tilde;
    assign key_minus_equal = ( jis_shift == 1 ) ? minus : equal;
    assign key_num9_rparen = ( jis_shift == 1 ) ? num9 : rparen;
    assign key_num8_lparen = ( jis_shift == 1 ) ? num8 : lparen;

    assign key_b = b;
    assign key_a = a;
    assign key_under = under;
    assign key_slash_quest = ( jis_shift == 1 ) ? slash : quest;
    assign key_dot_greater = ( jis_shift == 1 ) ? dot : greater;
    assign key_comma_less = ( jis_shift == 1 ) ? comma : less;
    assign key_rbracket_rbrace = ( jis_shift == 1 ) ? rbracket : rbrace;
    assign key_colon_star = ( jis_shift == 1 ) ? colon : star;


    assign keys_jis [0] = { key_num7_acute, key_num6_amper, key_num5_percent, key_num4_dollar, key_num3_hash, key_num2_dquote, key_num1_excl, key_num0 };
    assign keys_jis [1] = { key_semi_plus, key_lbracket_lbrace, key_at_backtick, key_yen_pipe, key_caret_tilde, key_minus_equal, key_num9_rparen, key_num8_lparen };
    assign keys_jis [2] = { key_b, key_a, key_under, key_slash_quest, key_dot_greater, key_comma_less, key_rbracket_rbrace, key_colon_star };
    assign keys_jis [3:5] = keys [3:5];
    assign keys_jis [6] = { keys[6][7:1], jis_shift };
    assign keys_jis [7:15] = keys [7:15];

endmodule


// ============================================================================
// kb_map_fr - teclado francés AZERTY (Philips VG-8020F) -> matriz japonesa
//
//         B7  B6  B5  B4  B3  B2  B1  B0        origen tras la reasignación
//  Row0_S  ]   [   (   '   "   @   &   }        <- dígitos dados la vuelta
//  Row0    7   6   5   4   3   2   1   0
//  Row1_S  M   *   ~   >   _   )   {   !
//  Row1    m   $   ^   <   -   `   9   8
//  Row2_S  B   Q   -   +   /   .   |   %
//  Row2    b   q   -   =   :   ;   #   \
//  Row4_S              ?   (B2)
//  Row4                ,   (B2)
//
// Diferencias con el teclado de fábrica:
//
//   Los dígitos van SIN shift. En el AZERTY original salen pulsando shift, lo
//   que obligaría a invertir el nivel en las diez teclas de dígito. Darles la
//   vuelta deja la fila 0 alineada con la japonesa y elimina esas diez.
//
//   Los siete acentuados sin equivalente japonés (e aguda, e grave, a grave,
//   u grave, c cedilla, sección y grado) dejan su sitio a los símbolos de
//   programación que al AZERTY le faltan. Las dos teclas muertas pasan a dar
//   circunflejo y tilde como caracteres.
//
//   Los pares de corchetes y llaves se reparten sobre dígitos contiguos:
//   corchetes sobre 6 y 7, llaves sobre 9 y 0.
//
//   Row2/B5 no se usa. Esa tecla no tiene función en el teclado de fábrica y
//   no se puede dar por cableada en todas las unidades.
//
// Con esto el teclado cubre el juego de caracteres japonés completo.
//
// Las letras se permutan: A y Q, W y Z, y la M pasa de Row1/B7 a Row4/B2.
//
// Este mapa no usa kana, así que el puerto no está.
// ============================================================================

module kb_map_fr(
    input  wire [7:0] keys [0:15],
    output wire [7:0] keys_jis [0:15]
);

    //characters
    wire num0;
    wire num1;
    wire num2;
    wire num3;
    wire num4;
    wire num5;
    wire num6;
    wire num7;
    wire num8;
    wire num9;
    wire amper;     //&
    wire percent;   //%
    wire dollar;    //$
    wire hash;      //#
    wire at;        //@
    wire excl;      //!
    wire rparen;    //)
    wire lparen;    //(
    wire colon;     //:
    wire semi;      //;
    wire rbrace;    //}
    wire rbracket;  //]
    wire lbrace;    //{
    wire lbracket;  //[
    wire pipe;      //|
    wire bslash;    //\
    wire plus;      //+
    wire equal;     //=
    wire under;     //_
    wire minus;     //-
    wire star;      //*
    wire quest;     //?
    wire slash;     ///
    wire greater;   //>
    wire dot;       //.
    wire less;      //<
    wire comma;     //,
    wire dquote;    //"
    wire caret;     //^
    wire tilde;     //~
    wire backtick;  //acento grave
    wire acute;     //acento agudo
    wire shift;


    assign shift =  keys [6][0];

    // Fila 0. Los dígitos pasan al nivel sin shift; el nivel con shift recibe
    // el símbolo que ya tenía la tecla, o uno de los que faltaban.
    //  ]   [   (   '   "   @   &   }
    //  7   6   5   4   3   2   1   0
    assign num7 = ~shift | keys [0][7];
    assign rbracket = shift | keys [0][7];      // corchete derecho sobre el 7

    assign num6 = ~shift | keys [0][6];
    assign lbracket = shift | keys [0][6];      // corchete izquierdo sobre el 6

    assign num5 = ~shift | keys [0][5];
    assign lparen = shift | keys [0][5];        // el paréntesis se queda aquí

    assign num4 = ~shift | keys [0][4];
    assign acute = shift | keys [0][4];         // el acento agudo se queda aquí

    assign num3 = ~shift | keys [0][3];
    assign dquote = shift | keys [0][3];        // las comillas se quedan aquí

    assign num2 = ~shift | keys [0][2];
    assign at = shift | keys [0][2];            // arroba sobre el 2

    assign num1 = ~shift | keys [0][1];
    assign amper = shift | keys [0][1];         // el ampersand se queda aquí

    assign num0 = ~shift | keys [0][0];
    assign rbrace = shift | keys [0][0];        // llave derecha sobre el 0

    //  M   *   ~   >   _   )   {   !
    //  m   $   ^   <   -   `   9   8
    assign dollar = ~shift | keys [1][6];
    assign star = shift | keys [1][6];

    assign caret = ~shift | keys [1][5];        // eran las dos teclas muertas:
    assign tilde = shift | keys [1][5];         // ahora dan su propio símbolo

    assign less = ~shift | keys [1][4];
    assign greater = shift | keys [1][4];

    assign minus = ~shift | keys [1][3];
    assign under = shift | keys [1][3];

    assign backtick = ~shift | keys [1][2];     // acento grave bajo el paréntesis
    assign rparen = shift | keys [1][2];

    assign num9 = ~shift | keys [1][1];
    assign lbrace = shift | keys [1][1];        // llave izquierda sobre el 9

    assign num8 = ~shift | keys [1][0];
    assign excl = shift | keys [1][0];

    //  B   Q   -   +   /   .   \   %
    //  b   q   -   =   :   ;   #   |
    //
    // Row2/B5 se deja sin usar: no tiene función de fábrica y no se puede dar
    // por cableada en todas las unidades.
    assign equal = ~shift | keys [2][4];
    assign plus = shift | keys [2][4];

    assign colon = ~shift | keys [2][3];
    assign slash = shift | keys [2][3];

    assign semi = ~shift | keys [2][2];
    assign dot = shift | keys [2][2];

    assign hash = ~shift | keys [2][1];         // la almohadilla se queda sin shift
    assign pipe = shift | keys [2][1];          // barra vertical encima

    assign bslash = ~shift | keys [2][0];       // el hueco que dejó la u grave
    assign percent = shift | keys [2][0];

    //  ?   en Row4/B2
    //  ,
    assign comma = ~shift | keys [4][2];
    assign quest = shift | keys [4][2];

    wire invert_shift;

    //jis keys
    wire key_num7_acute;
    wire key_num6_amper;
    wire key_num5_percent;
    wire key_num4_dollar;
    wire key_num3_hash;
    wire key_num2_dquote;
    wire key_num1_excl;
    wire key_num0;

    wire key_semi_plus;
    wire key_lbracket_lbrace;
    wire key_at_backtick;
    wire key_yen_pipe;
    wire key_caret_tilde;
    wire key_minus_equal;
    wire key_num9_rparen;
    wire key_num8_lparen;

    wire key_b;
    wire key_a;
    wire key_under;
    wire key_slash_quest;
    wire key_dot_greater;
    wire key_comma_less;
    wire key_rbracket_rbrace;
    wire key_colon_star;


    wire jis_shift;

    // Caracteres que en el japonés viven en el nivel de shift contrario al que
    // ocupan aquí. Son diez: el precio de mantener cada símbolo en su tecla.
    assign invert_shift = ~rbracket | ~lbracket | ~at | ~dollar | ~less | ~backtick
                        | ~equal | ~slash | ~dot | ~hash;
    assign jis_shift = shift ^ invert_shift;

    assign key_num7_acute = ( jis_shift == 1 ) ? num7 : acute;
    assign key_num6_amper = ( jis_shift == 1 ) ? num6 : amper;
    assign key_num5_percent = ( jis_shift == 1 ) ? num5 : percent;
    assign key_num4_dollar = ( jis_shift == 1 ) ? num4 : dollar;
    assign key_num3_hash = ( jis_shift == 1 ) ? num3 : hash;
    assign key_num2_dquote = ( jis_shift == 1 ) ? num2 : dquote;
    assign key_num1_excl = ( jis_shift == 1 ) ? num1 : excl;
    assign key_num0 = ( jis_shift == 1 ) ? num0 : 1'b1;     // el japonés no da shift+0

    assign key_semi_plus = ( jis_shift == 1 ) ? semi : plus;
    assign key_lbracket_lbrace = ( jis_shift == 1 ) ? lbracket : lbrace;
    assign key_at_backtick = ( jis_shift == 1 ) ? at : backtick;
    assign key_yen_pipe = ( jis_shift == 1 ) ? bslash : pipe;
    assign key_caret_tilde = ( jis_shift == 1 ) ? caret : tilde;
    assign key_minus_equal = ( jis_shift == 1 ) ? minus : equal;
    assign key_num9_rparen = ( jis_shift == 1 ) ? num9 : rparen;
    assign key_num8_lparen = ( jis_shift == 1 ) ? num8 : lparen;

    assign key_b = keys [2][7];
    assign key_a = keys [4][6];                             // AZERTY: la A está en Row4/B6
    assign key_under = under;
    assign key_slash_quest = ( jis_shift == 1 ) ? slash : quest;
    assign key_dot_greater = ( jis_shift == 1 ) ? dot : greater;
    assign key_comma_less = ( jis_shift == 1 ) ? comma : less;
    assign key_rbracket_rbrace = ( jis_shift == 1 ) ? rbracket : rbrace;
    assign key_colon_star = ( jis_shift == 1 ) ? colon : star;


    assign keys_jis [0] = { key_num7_acute, key_num6_amper, key_num5_percent, key_num4_dollar, key_num3_hash, key_num2_dquote, key_num1_excl, key_num0 };
    assign keys_jis [1] = { key_semi_plus, key_lbracket_lbrace, key_at_backtick, key_yen_pipe, key_caret_tilde, key_minus_equal, key_num9_rparen, key_num8_lparen };
    assign keys_jis [2] = { key_b, key_a, key_under, key_slash_quest, key_dot_greater, key_comma_less, key_rbracket_rbrace, key_colon_star };

    // Filas de letras. C a J coinciden; en las otras dos el AZERTY permuta
    // A con Q, W con Z, y coloca la M donde el japonés pone la coma.
    assign keys_jis [3] = keys [3];
    assign keys_jis [4] = { keys[4][7], keys[2][6], keys[4][5], keys[4][4],
                            keys[4][3], keys[1][7], keys[4][1], keys[4][0] };
    assign keys_jis [5] = { keys[5][4], keys[5][6], keys[5][5], keys[5][7],
                            keys[5][3], keys[5][2], keys[5][1], keys[5][0] };

    assign keys_jis [6] = { keys[6][7:1], jis_shift };
    assign keys_jis [7:15] = keys [7:15];

endmodule


// ============================================================================
// kb_map_vg - Philips VG-8000 y VG-8010 -> matriz del teclado japonés
//
//         B7  B6  B5  B4  B3  B2  B1  B0        origen (VG-8000 / VG-8010)
//  Row0_S  B   L   --  |   !   S   X   <
//  Row0    b   l   --  \   1   s   x   ,
//  Row1_S  V   J   +   ~   Q   A   C   N
//  Row1    v   j   =   `   q   a   c   n
//  Row2_S  G   *   )   }   W   F   Z   M
//  Row2    g   8   0   ]   w   f   z   m
//  Row3_S  T   I   _   :   @   D   U   ?
//  Row3    t   i   -   ;   2   d   u   /
//  Row4_S  ^   K   P   "   #   R   &   H
//  Row4    6   k   p   �   3   r   7   h
//  Row5_S  %   O   (   {   $   E   Y   >
//  Row5    5   o   9   [   4   e   y   .
//
// Este teclado es el internacional de siempre, pero cableado en otras
// posiciones de la matriz: 47 de sus 48 teclas llevan la misma pareja de
// caracteres que alguna del Toshiba HX-10, con el mismo nivel de shift. No hay
// ningún carácter que cambie de nivel ni ninguno que sobre o falte.
//
// Por eso aquí no se repite la lógica de caracteres: basta reordenar las filas
// 0-5 a la disposición internacional y pasarlas por kb_map_intl, que ya hace la
// traducción a japonés y está verificada.
//
// Row0/B5 no está cableada; en el internacional ocupa el sitio de la tecla de
// la libra (Row2/B5), que kb_map_intl tampoco traduce.
//
// Las filas 6 a 8 coinciden con las del internacional, así que pasan tal cual.
// Ojo para el nivel superior: en estas máquinas GRAPH y CODE son conmutadores.
// Una pulsación activa el modo y la siguiente lo desactiva, aunque el bit de la
// matriz vuelva a 1 al soltar la tecla. Eso lo resuelve la BIOS, no este mapa.
//
// El modo CODE (kana) sigue funcionando: la tecla pasa sin tocar y kb_map_intl
// recibe la señal, de modo que SHIFT + dígito se queda en su propia tecla. Los
// caracteres extendidos que salgan no serán los del teclado original, porque
// los da la BIOS japonesa, pero la funcionalidad se mantiene.
// ============================================================================

module kb_map_vg(
    input  wire [7:0] keys [0:15],
    input  wire       kana,
    output wire [7:0] keys_jis [0:15]
);

    wire [7:0] keys_intl [0:15];

    // Reordena las filas 0-5. Cada término es la tecla del VG-8000 que lleva
    // el carácter que el teclado internacional tiene en esa posición.
    //
    //                              B7          B6          B5          B4          B3          B2          B1          B0
    assign keys_intl [0] = { keys[4][1], keys[4][7], keys[5][7], keys[5][3], keys[4][3], keys[3][3], keys[0][3], keys[2][5] };
    assign keys_intl [1] = { keys[3][4], keys[2][4], keys[5][4], keys[0][4], keys[1][5], keys[3][5], keys[5][5], keys[2][6] };
    assign keys_intl [2] = { keys[0][7], keys[1][2], 1'b1      , keys[3][0], keys[5][0], keys[0][0], keys[1][4], keys[4][4] };
    assign keys_intl [3] = { keys[1][6], keys[3][6], keys[4][0], keys[2][7], keys[2][2], keys[5][2], keys[3][2], keys[1][1] };
    assign keys_intl [4] = { keys[4][2], keys[1][3], keys[4][5], keys[5][6], keys[1][0], keys[2][0], keys[0][6], keys[4][6] };
    assign keys_intl [5] = { keys[2][1], keys[5][1], keys[0][1], keys[2][3], keys[1][7], keys[3][1], keys[3][7], keys[0][2] };

    // Modificadores y teclas especiales: mismas posiciones que el internacional
    assign keys_intl [6:15] = keys [6:15];

    kb_map_intl u_map_intl (
        .keys       (keys_intl),
        .kana       (kana),
        .keys_jis   (keys_jis)
    );

endmodule


// ============================================================================
// kb_map_es - teclado español -> matriz del teclado japonés
//
//         B7  B6  B5  B4  B3  B2  B1  B0        origen (español)
//  Row0_S  &   ^   %   $   #   @   !   )
//  Row0    7   6   5   4   3   2   1   0
//  Row1_S  ~   }   {   |   +   _   (   *       <- B7 era la eñe mayúscula
//  Row1    `   ]   [   \   =   -   9   8       <- B7 era la eñe minúscula
//  Row2_S  B   A   --  ?   >   <   :   "       <- B5 son teclas muertas
//  Row2    b   a   --  /   .   ,   ;   '
//
// Es el mismo teclado que el internacional salvo en tres celdas: 45 de sus 48
// teclas están en la misma posición y con la misma pareja de caracteres. Por
// eso aquí solo se recolocan esas tres y se pasa la matriz por kb_map_intl.
//
//   Row2/B1  lleva ; y : , que en el internacional están en Row1/B7. Es la
//            única tecla que cambia de sitio, y conserva su nivel de shift.
//   Row1/B7  lleva la eñe minúscula y mayúscula, que no existen en el juego de
//            caracteres japonés. Se reaprovecha para el acento grave y la
//            tilde, los dos caracteres japoneses que este teclado no tiene.
//   Row2/B5  es una tecla muerta que compone acentos; no emite código. En el
//            internacional esa posición lleva la libra, que kb_map_intl
//            tampoco traduce.
//
// La tecla de la eñe va a Row2/B1 del internacional, que es justo donde este
// tiene el acento grave y la tilde, con los mismos niveles de shift. Así el
// teclado alcanza el juego japonés completo sin ninguna inversión nueva.
//
// Cubre siete modelos, todos con la misma matriz: Sony HB-20P y HB-F9S,
// Mitsubishi ML-G1 ES y ML-G3 ES, Spectravideo SVI-728 ES, y las argentinas
// Talent DPC-200 y TPC-310.
// ============================================================================

module kb_map_es(
    input  wire [7:0] keys [0:15],
    input  wire       kana,
    output wire [7:0] keys_jis [0:15]
);

    wire [7:0] keys_intl [0:15];

    assign keys_intl [0] = keys [0];

    // Row1/B7 del internacional recibe el ; y : que aquí está en Row2/B1
    assign keys_intl [1] = { keys[2][1], keys[1][6], keys[1][5], keys[1][4],
                             keys[1][3], keys[1][2], keys[1][1], keys[1][0] };

    // Row2/B1 del internacional (acento grave y tilde) recibe la tecla de la
    // eñe, que aquí está en Row1/B7
    assign keys_intl [2] = { keys[2][7], keys[2][6], keys[2][5], keys[2][4],
                             keys[2][3], keys[2][2], keys[1][7], keys[2][0] };

    assign keys_intl [3:5] = keys [3:5];
    assign keys_intl [6:15] = keys [6:15];

    kb_map_intl u_map_intl (
        .keys       (keys_intl),
        .kana       (kana),
        .keys_jis   (keys_jis)
    );

endmodule
