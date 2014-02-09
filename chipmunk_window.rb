require 'gosu'
require 'chipmunk'

module ZOrder
  BACKGROUND, STARS, PLAYER, UI = *0..3
end

class Numeric
  def radians_to_vec2
    CP::Vec2.new Math.cos(self), Math.sin(self)
  end
end

# Number of updates, per game update, that the physics engine processes
SUBSTEPS = 6

SCREEN_WIDTH  = 640
SCREEN_HEIGHT = 480

class GameWindow < Gosu::Window

  def initialize
    super SCREEN_WIDTH, SCREEN_HEIGHT, false
    self.caption = 'Gosu w/ Chipmunk Game tutorial'

    @background_image = Gosu::Image.new(self, 'media/Space.png', true)

    @beep = Gosu::Sample.new(self, "media/Beep.wav")

    @score = 0
    @font = Gosu::Font.new(self, Gosu.default_font_name, 20)

    # Delta time, because PHYSICS!
    @dt = 1.0/60.0

    # Define the physics space and set the 'friction'
    @space = CP::Space.new
    @space.damping = 0.8

    # Create a player body and shape
    body = CP::Body.new 10.0, 150.0
    shape_array = [CP::Vec2.new(-25.0, -25.0), CP::Vec2.new(-25.0, 25.0), CP::Vec2.new(25.0, 1.0), CP::Vec2.new(25.0, -1.0)]
    shape = CP::Shape::Poly.new(body, shape_array, CP::Vec2.new(0,0))
    shape.collision_type = :ship

    @space.add_body body
    @space.add_shape shape

    @player = Player.new self, shape
    @player.warp CP::Vec2.new(SCREEN_WIDTH/2, SCREEN_HEIGHT/2)

    @star_animation = Gosu::Image.load_tiles(self, 'media/Star.png', 25, 25, false)
    @stars = []

    # Ship collects stars
    @remove_shapes = []
    @space.add_collision_func(:ship, :star) do |ship_shape, star_shape|
      @score += 10
      @beep.play
      @remove_shapes << star_shape
    end

    # We don't care if star bump
    @space.add_collision_func(:star, :star, &nil)

  end

  def update
    SUBSTEPS.times do

      @remove_shapes.each do |shape|
        @stars.delete_if { |star| star.shape == shape }
        @space.remove_body shape.body
        @space.remove_shape shape
      end
      @remove_shapes.clear

      @player.shape.body.reset_forces
      @player.validate_position

      @player.turn_left if [Gosu::KbLeft, Gosu::GpLeft].any? { |k| button_down? k }
      @player.turn_right if [Gosu::KbRight, Gosu::GpRight].any? { |k| button_down? k }
      @player.accelerate if [Gosu::KbUp, Gosu::GpButton0].any? { |k| button_down? k }

      @space.step @dt
    end

    if rand(100) < 4 and @stars.size < 25
      body = CP::Body.new 0.0001, 0.0001
      shape = CP::Shape::Circle.new body, 25/2, CP::Vec2.new(0.0, 0.0)
      shape.collision_type = :star

      @space.add_body body
      @space.add_shape shape
      @stars.push Star.new(@star_animation, shape)
    end
  end

  def draw
    @background_image.draw 0, 0, ZOrder::BACKGROUND
    @player.draw
    @stars.each { |s| s.draw }
    @font.draw "Score: #{@score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00
  end

  def button_down id
    close if id == Gosu::KbEscape
  end

end

class Player

  attr_reader :shape

  def initialize window, shape
    @image = Gosu::Image.new window, 'media/Starfighter.bmp', false
    @shape = shape
    @shape.body.p = CP::Vec2.new(0.0, 0.0) # position
    @shape.body.v = CP::Vec2.new(0.0, 0.0) # velocity

    # Keep in mind that down the screen is positive y, which means that PI/2 radians,
    # which you might consider the top in the traditional Trig unit circle sense is actually
    # the bottom; thus 3PI/2 is the topy
    @shape.body.a = (3*Math::PI/2.0)
  end

  def warp vect
    @shape.body.p = vect
  end

  def turn_left
    @shape.body.t -= 400.0/SUBSTEPS
  end

  def turn_right
    @shape.body.t += 400.0/SUBSTEPS
  end

  def accelerate
    @shape.body.apply_force((@shape.body.a.radians_to_vec2 * 1000.0/SUBSTEPS), CP::Vec2.new(0.0, 0.0))
  end

  def validate_position
    l_position = CP::Vec2.new @shape.body.p.x % SCREEN_WIDTH, @shape.body.p.y % SCREEN_HEIGHT
    @shape.body.p = l_position
  end

  def draw
    @image.draw_rot @shape.body.p.x, @shape.body.p.y, ZOrder::PLAYER, @shape.body.a.radians_to_gosu
  end

end

class Star

  attr_reader :shape

  def initialize animation, shape
    @animation   = animation
    @color       = Gosu::Color.new 0xff000000
    @color.red   = rand(256 - 40) + 40
    @color.green = rand(256 - 40) + 40
    @color.blue  = rand(256 - 40) + 40
    @shape = shape
    @shape.body.p = CP::Vec2.new(rand * SCREEN_WIDTH, rand * SCREEN_HEIGHT)
    @shape.body.v = CP::Vec2.new(0.0, 0.0)
    @shape.body.a = (3*Math::PI/2.0)
  end

  def draw
    img = @animation[Gosu.milliseconds / 100 % @animation.size]
    img.draw shape.body.p.x - img.width / 2.0,
             shape.body.p.y - img.height / 2.0,
             ZOrder::STARS,
             1,
             1,
             @color,
             :add
  end
end

window = GameWindow.new
window.show
