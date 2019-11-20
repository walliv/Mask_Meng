library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port ( clk : in  STD_LOGIC := '0';
           HS,VS,R,G,B, frame_tick : out  STD_LOGIC := '0';
			  start_pos, end_pos: in std_logic_vector(7 downto 0);
			  
			  --pamet usporadani levelu
			  lvl_mem_add: out std_logic_vector(5 downto 0);
			  lvl_mem_data: in std_logic_vector(2 downto 0);
			  
			  --signaly pro pohyb
			  move: in std_logic := '0';
			  reset: in std_logic := '0';
			  ack: out std_logic := '0');
end top;

architecture Behavioral of top is

	component vga_sync is
		Port ( clk : in  STD_LOGIC;
           h_sync, v_sync,video_on, frame_tick : out  STD_LOGIC;
           pixel_x, pixel_y : out  STD_LOGIC_VECTOR (10 downto 0));
	end component;

	component level_generator is
		Port ( pix_x, pix_y : in  STD_LOGIC_VECTOR (10 downto 0);
			  pixx_offs, pixy_offs, inside_pixx_offs, inside_pixy_offs : out std_logic_vector(10 downto 0);
			  mem_add: out std_logic_vector(5 downto 0);
			  mem_data: in std_logic_vector(2 downto 0);
           clock : in  STD_LOGIC;
			  border_draw_en: out  STD_LOGIC;
			  selected_object: out std_logic_vector(2 downto 0);
			  
			  start_pos, end_pos: std_logic_vector(7 downto 0);
			  
			  obj_offs_x, obj_offs_y: out std_logic_vector(8 downto 0);
		--experimentarni signaly
			  move, reset : in  STD_LOGIC;
			  ack: out std_logic
			  );
	end component;

	component object_generator is
		Port ( clk: std_logic;
			  sel: in std_logic_vector(2 downto 0);
           pixx, pixy : in  STD_LOGIC_VECTOR (10 downto 0);
           offset_x, offset_y : in  STD_LOGIC_VECTOR (8 downto 0);
			  white_dots_en, obj_en: out std_logic;
			  
			  --signaly pro pamet
			  mem_read_enable: out std_logic;
			  mem_add_x: out std_logic_vector(11 downto 0);
			  mem_add_y: out std_logic_vector(2 downto 0)
			);
	end component;

	component graphic_rom is
		Port ( clock, read_enable : in  STD_LOGIC;
           address_x: in  STD_LOGIC_VECTOR (11 downto 0);
			  address_y: in  STD_LOGIC_VECTOR (2 downto 0);
           data_out : out  STD_LOGIC_VECTOR (2 downto 0));
	end component;

	component levels_rom is
		Port ( clock: in  STD_LOGIC;
           address_x : in  STD_LOGIC_VECTOR (5 downto 0);
           data_out : out  STD_LOGIC_VECTOR (2 downto 0));
	end component;

	--vnitrni signaly pro synchronizaci grafiky
	signal vid_on: std_logic := '0';
	signal pxx, pxy: std_logic_vector(10 downto 0) := (others => '0');
	signal color: std_logic_vector(2 downto 0);

	--signaly pro grafickou pamet
	signal graphic_mem_addx: std_logic_vector(11 downto 0) := (others => '0');
	signal graphic_mem_addy: std_logic_vector(2 downto 0) := (others => '0');
	signal graphic_mem_re: std_logic;
	signal graphic_mem_data: std_logic_vector(2 downto 0);

	--offsety grafickych obejktu
	signal gr_offs_x, gr_offs_y: std_logic_vector(8 downto 0);

<<<<<<< HEAD
	--signaly pro rizeni generatoru objektu
	signal selected_object:std_logic_vector(2 downto 0);
	signal border_draw_en:std_logic;
=======
component color_output_mux is
    Port ( floor_obj, wall_obj, stone_obj,player_obj, food_obj, gui_obj : in  STD_LOGIC_VECTOR (2 downto 0);
           R,G,B : out  STD_LOGIC;
           floor_sel, wall_sel, stone_sel, player_sel,food_sel, gui_sel: in  STD_LOGIC);
end component;

component gui_generator is
	Port ( pix_x, pix_y : in  STD_LOGIC_VECTOR (10 downto 0);
			 clk : in STD_LOGIC;
			 lvl_jednotky : in STD_LOGIC_VECTOR (3 downto 0);
			 lvl_desitky : in STD_LOGIC_VECTOR (3 downto 0);
			 stp_jednotky : in STD_LOGIC_VECTOR (3 downto 0);
			 stp_desitky : in STD_LOGIC_VECTOR (3 downto 0);
			 color : out STD_LOGIC_VECTOR (2 downto 0);
			 gui_sel : out STD_LOGIC);
end component;
>>>>>>> 34bab866f0d5f05ec958d45357540553443ca86e

	--signaly pixelu s offsetem
	signal pixx_arena, pixy_arena, inside_pix_x, inside_pix_y, pixx_selected, pixy_selected: std_logic_vector(10 downto 0) := (others => '0');

	--signaly vystupniho multiplexeru
	signal graphics_enable, white_dots_en: std_logic;

<<<<<<< HEAD
	--signaly zabyvajici se pohybem
	signal start_pos_reg_out, end_pos_reg_out: std_logic_vector(7 downto 0);

	--signaly zpozdovaaci linky
	signal pixx_1, pixx_2, pixy_1, pixy_2: std_logic_vector(10 downto 0);
=======
--vnitrni signaly z vystupu generatoru objektu
signal floor_pic, wall_pic, stone_pic, player_pic, food_pic, gui_pic: std_logic_vector(2 downto 0) := (others => '0');

--signaly pro povoleni vykreslovani objektu
signal gen_floor_en, gen_wall_en, gen_stone_en,gen_food_en, gen_player_en, border_draw_en, gui_en:std_logic;

signal selected_object:std_logic_vector(2 downto 0);

--signaly pixelu s offsetem
signal pixx_arena, pixy_arena, inside_pix_x, inside_pix_y, pixx_selected, pixy_selected: std_logic_vector(10 downto 0) := (others => '0');
>>>>>>> 34bab866f0d5f05ec958d45357540553443ca86e

--signaly pro tahy a levely
signal lvl_1: std_logic_vector(3 downto 0) := "0101";
signal lvl_10: std_logic_vector(3 downto 0) := "0010";
signal stp_1: std_logic_vector(3 downto 0) := "0100";
signal stp_10: std_logic_vector(3 downto 0) := "0100";

begin

	reg_color: process(clk) is			--vystupni registr barev
	begin
		if(rising_edge(clk)) then
			if(vid_on ='1') then
				R <= color(2);
				G <= color(1);
				B <= color(0);
			else
				R <= '0';
				G <= '0';
				B <= '0';
			end if;
		end if;
<<<<<<< HEAD
	end process;

	process(clk)
	begin
		if(rising_edge(clk)) then
			pixx_1 <= pixx_selected;
			pixx_2 <= pixx_1;
			pixy_1 <= pixy_selected;
			pixy_2 <= pixy_1;
		end if;
	end process;

	--multiplexery citacu radku a sloupcu obrazu
	with border_draw_en select
	pixx_selected <= pixx_arena when '1',
							inside_pix_x when '0',
							(others => '0') when others;
						
	with border_draw_en select
	pixy_selected <= pixy_arena when '1',
							inside_pix_y when '0',
							(others => '0') when others;
						
	--vystupni multiplexer grafickych objektu
	color <= "111" when white_dots_en = '1' else
				graphic_mem_data when ((graphics_enable = '1') and (white_dots_en = '0')) else
				"000";
						
		move_register: process(clk)
		begin
			if(rising_edge(clk)) then
				start_pos_reg_out <= start_pos;
				end_pos_reg_out <= end_pos;
			end if;
		end process;
=======
	end if;
end process;

info_generator: gui_generator
		port map(
			clk => clk,
			pix_x => pxx,
			pix_y => pxy,
			gui_sel => gui_en,
			color => gui_pic,
			lvl_jednotky => lvl_1,
			lvl_desitky => lvl_10,
			stp_jednotky => stp_1,
			stp_desitky => stp_10);
>>>>>>> 34bab866f0d5f05ec958d45357540553443ca86e
			
	synchronizer: vga_sync
		port map(
			clk => clk,
			h_sync => HS,
			v_sync => VS,
			video_on => vid_on,
			pixel_x => pxx,
			pixel_y => pxy,
			frame_tick => frame_tick);
			
	lvl_load_generator: level_generator
		port map(
		  pix_x => pxx, 
		  pix_y => pxy, 
		  pixx_offs => pixx_arena,
		  pixy_offs => pixy_arena,
		  inside_pixx_offs => inside_pix_x,
		  inside_pixy_offs => inside_pix_y,
		  mem_add => lvl_mem_add,
		  mem_data => lvl_mem_data,
        clock => clk,
		  move => move,
		  reset => reset,					--reset automatu zabyvajicim se pohybem
		  ack => ack,
		  start_pos => start_pos_reg_out,
		  end_pos => end_pos_reg_out,
		  obj_offs_x => gr_offs_x, 
		  obj_offs_y => gr_offs_y,
		  border_draw_en => border_draw_en,
		  selected_object => selected_object
		);
		
	graphics_generator:object_generator
		port map(
			clk => clk,
			sel => selected_object,
         pixx => pixx_2,
			pixy => pixy_2,
         offset_x => gr_offs_x,
			offset_y => gr_offs_y,	
			white_dots_en => white_dots_en,
			obj_en => graphics_enable,
			mem_read_enable => graphic_mem_re,
			mem_add_x => graphic_mem_addx,
			mem_add_y => graphic_mem_addy
		);
		
	sprite_memory: graphic_rom
		port map(
			clock => clk,
			read_enable => graphic_mem_re,
         address_x => graphic_mem_addx,
			address_y => graphic_mem_addy,
         data_out => graphic_mem_data
		);

<<<<<<< HEAD
=======
floor_object_generator: floor_object
		port map(
			pix_x => inside_pix_x,
			pix_y => inside_pix_y,
         enable => gen_floor_en,
			clk => clk,
         color => floor_pic
		);
			
wall_object_generator: wall_object
		port map(
			pix_x => pixx_selected,
			pix_y => pixy_selected,
         enable => gen_wall_en,
			clk => clk,
         color => wall_pic
		);
		
stone_object_generator: stone_obj
		port map(
			pix_x => inside_pix_x,
			pix_y => inside_pix_y,
         enable => gen_stone_en,
			clk => clk,
         color => stone_pic
		);		
		
player_object_generator: player_obj
		port map(
			pix_x => inside_pix_x,
			pix_y => inside_pix_y,
         enable => gen_player_en,
			clk => clk,
         color => player_pic
		);		
		
food_object_generator: food_obj
		port map(
			pix_x => inside_pix_x,
			pix_y => inside_pix_y,
         enable => gen_food_en,
			clk => clk,
         color => food_pic
		);		
						
col_out_mux: color_output_mux
		port map(
			floor_obj => floor_pic, 
			wall_obj => wall_pic, 
			player_obj => player_pic, 
			stone_obj => stone_pic, 
			food_obj => food_pic,
         floor_sel => gen_floor_en, 
			wall_sel => gen_wall_en, 
			player_sel => gen_player_en,
			stone_sel => gen_stone_en,
			food_sel => gen_food_en,
			gui_sel => gui_en,
			gui_obj => gui_pic,
			R => red,
			G => green,
			B => blue);
>>>>>>> 34bab866f0d5f05ec958d45357540553443ca86e
end Behavioral;

