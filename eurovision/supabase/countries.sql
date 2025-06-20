-- Eurovision 2025 Countries Insert Query - Complete with Actual Running Orders
-- Based on actual Eurovision 2025 performance orders and results

INSERT INTO public.countries (
    name, 
    code, 
    semi_final, 
    final, 
    flag, 
    artist_name, 
    song_name, 
    semi_running_order, 
    final_running_order
) VALUES 

-- GRAND FINAL PARTICIPANTS (26 countries) - Performance Order

-- Grand Final Running Order (1-26)
('Norway', 'NO', 1, true, 'norway.png', 'Kyle Alessandro', 'Lighter', 14, 1),
('Luxembourg', 'LU', 2, true, 'luxembourg.png', 'Laura Thorn', 'La Poupée Monte Le Son', 14, 2),
('Estonia', 'EE', 1, true, 'estonia.png', 'Tommy Cash', 'Espresso Macchiato', 1, 3),
('Israel', 'IL', 2, true, 'israel.png', 'Yuval Raphael', 'New Day Will Rise', 13, 4),
('Lithuania', 'LT', 2, true, 'lithuania.png', 'Katarsis', 'Tavo Akys', 7, 5),
('Spain', 'ES', NULL, true, 'spain.png', 'Melody', 'ESA DIVA', NULL, 6),
('Ukraine', 'UA', 1, true, 'ukraine.png', 'Ziferblat', 'Bird of Pray', 7, 7),
('United Kingdom', 'GB', NULL, true, 'united_kingdom.png', 'Remember Monday', 'What The Hell Just Happened?', NULL, 8),
('Austria', 'AT', 2, true, 'austria.png', 'JJ', 'Wasted Love', 3, 9),
('Iceland', 'IS', 1, true, 'iceland.png', 'VÆB', 'RÓA', 2, 10),
('Latvia', 'LV', 2, true, 'latvia.png', 'Tautumeitas', 'Bur Man Laimi', 6, 11),
('Netherlands', 'NL', 1, true, 'netherlands.png', 'Claude', 'C''est La Vie', 13, 12),
('Finland', 'FI', 2, true, 'finland.png', 'Erika Vikman', 'ICH KOMME', 11, 13),
('Italy', 'IT', NULL, true, 'italy.png', 'Lucio Corsi', 'Volevo Essere Un Duro', NULL, 14),
('Poland', 'PL', 1, true, 'poland.png', 'Justyna Steczkowska', 'GAJA', 3, 15),
('Germany', 'DE', NULL, true, 'germany.png', 'Abor & Tynna', 'Baller', NULL, 16),
('Greece', 'GR', 2, true, 'greece.png', 'Klavdia', 'Asteromáta', 4, 17),
('Armenia', 'AM', 2, true, 'armenia.png', 'PARG', 'SURVIVOR', 1, 18),
('Switzerland', 'CH', NULL, true, 'switzerland.png', 'Zoë Më', 'Voyage', NULL, 19),
('Malta', 'MT', 2, true, 'malta.png', 'Miriana Conte', 'SERVING', 15, 20),
('Portugal', 'PT', 1, true, 'portugal.png', 'NAPA', 'Deslocado', 4, 21),
('Denmark', 'DK', 2, true, 'denmark.png', 'Sissal', 'Hallucination', 10, 22),
('Sweden', 'SE', 1, true, 'sweden.png', 'KAJ', 'Bara Bada Bastu', 6, 23),
('France', 'FR', NULL, true, 'france.png', 'Louane', 'maman', NULL, 24),
('San Marino', 'SM', 1, true, 'san_marino.png', 'Gabry Ponte', 'Tutta L''Italia', 15, 25),
('Albania', 'AL', 1, true, 'albania.png', 'Shkodra Elektronike', 'Zjerm', 8, 26),

-- SEMI-FINAL 1 NON-QUALIFIERS (May 13, 2025)
('Slovenia', 'SI', 1, false, 'slovenia.png', 'Klemen', 'How Much Time Do We Have Left', 5, NULL),
('Azerbaijan', 'AZ', 1, false, 'azerbaijan.png', 'Mamagama', 'Run With U', 9, NULL),
('Belgium', 'BE', 1, false, 'belgium.png', 'Red Sebastian', 'Strobe Lights', 10, NULL),
('Croatia', 'HR', 1, false, 'croatia.png', 'Marko Bošnjak', 'Poison Cake', 11, NULL),
('Cyprus', 'CY', 1, false, 'cyprus.png', 'Theo Evan', 'Shh', 12, NULL),

-- SEMI-FINAL 2 NON-QUALIFIERS (May 15, 2025)
('Australia', 'AU', 2, false, 'australia.png', 'Go-Jo', 'Milkshake Man', 2, NULL),
('Ireland', 'IE', 2, false, 'ireland.png', 'EMMY', 'Laika Party', 5, NULL),
('Montenegro', 'ME', 2, false, 'montenegro.png', 'Nina Žižić', 'Dobrodošli', 8, NULL),
('Czech Republic', 'CZ', 2, false, 'czech_republic.png', 'ADONXS', 'Kiss Kiss Goodbye', 9, NULL),
('Georgia', 'GE', 2, false, 'georgia.png', 'Mariam Shengelia', 'Freedom', 12, NULL),
('Serbia', 'RS', 2, false, 'serbia.png', 'Princ', 'Mila', 16, NULL);

-- Note: This query includes the actual performance running orders from Eurovision 2025:
-- Semi-Final 1: May 13, 2025 (15 countries performed, 10 qualified + Albania as last qualifier)
-- Semi-Final 2: May 15, 2025 (16 countries performed, 10 qualified)
-- Grand Final: May 17, 2025 (26 countries performed in the order shown above)
-- Big 5 + Switzerland were pre-qualified for the final but some also performed in semi-finals as guests