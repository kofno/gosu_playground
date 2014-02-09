require 'gosu'

module ZOrder
  BACKGROUND, STARS, PLAYER, UI = *0..3
end

class GameWindow < Gosu::Window

  def initialize
    super 640, 480, false
    self.caption = 'Gosu Game tutorial'

    @background_image = Gosu::Image.new(self, 'media/Space.png', true)

    @player = Player.new self
    @player.warp 320, 240

    @star_animation = Gosu::Image.load_tiles(self, 'media/Star.png', 25, 25, false)
    @stars = []

    @font = Gosu::Font.new(self, Gosu.default_font_name, 20)
  end

  def update
    @player.turn_left if [Gosu::KbLeft, Gosu::GpLeft].any? { |k| button_down? k }
    @player.turn_right if [Gosu::KbRight, Gosu::GpRight].any? { |k| button_down? k }
    @player.accelerate if [Gosu::KbUp, Gosu::GpButton0].any? { |k| button_down? k }
    @player.move
    @player.collect_stars @stars

    if rand(100) < 4 and @stars.size < 25
      @stars.push Star.new(@star_animation)
    end
  end

  def draw
    @background_image.draw 0, 0, ZOrder::BACKGROUND
    @player.draw
    @stars.each { |s| s.draw }
    @font.draw "Score: #{@player.score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xffffff00
  end

  def button_down id
    close if id == Gosu::KbEscape
  end

end

class Player

  attr_reader :score

  def initialize window
    @image = Gosu::Image.new window, 'media/Starfighter.bmp', false
    @beep = Gosu::Sample.new(window, "media/Beep.wav")
    @x = @y = @velocity_x = @velocity_y = @angle = 0.0
    @score = 0
  end

  def warp x, y
    @x, @y = x, y
  end

  def turn_left
    @angle -= 4.5
  end

  def turn_right
    @angle += 4.5
  end

  def accelerate
    @velocity_x += Gosu.offset_x @angle, 0.5
    @velocity_y += Gosu.offset_y @angle, 0.5
  end

  def move
    @x += @velocity_x
    @y += @velocity_y
    @x %= 640
    @y %= 480

    @velocity_x *= 0.95
    @velocity_y *= 0.95
  end

  def draw
    @image.draw_rot @x, @y, ZOrder::PLAYER, @angle
  end

  def collect_stars stars
    stars.reject! do |star|
      if Gosu.distance(@x, @y, star.x, star.y) < 35
        @score += 1
        @beep.play
        true
      else
        false
      end
    end
  end
end

class Star

  attr_reader :x, :y

  def initialize animation
    @animation   = animation
    @color       = Gosu::Color.new 0xff000000
    @color.red   = rand(256 - 40) + 40
    @color.green = rand(256 - 40) + 40
    @color.blue  = rand(256 - 40) + 40
    @x           = rand * 640
    @y           = rand * 480
  end

  def draw
    img = @animation[Gosu.milliseconds / 100 % @animation.size]
    img.draw @x - img.width / 2.0,
             @y - img.height / 2.0,
             ZOrder::STARS,
             1,
             1,
             @color,
             :add
  end
end

window = GameWindow.new
window.show
