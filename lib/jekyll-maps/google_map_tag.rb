module Jekyll
  module Maps
    class GoogleMapTag < Liquid::Tag
      JS_LIB_NAME        = "jekyllMaps".freeze
      DEFAULT_MAP_WIDTH  = 600
      DEFAULT_MAP_HEIGHT = 400

      def initialize(_, args, _)
        @args   = OptionsParser.parse(args)
        super
      end

      def render(context)
        @finder = LocationFinder.new(@args)
        locations = @finder.find(context.registers[:site], context.registers[:page])
        @args[:attributes][:id] ||= SecureRandom.uuid

        <<HTML
<div #{render_attributes}></div>
<script type='text/javascript'>
  #{JS_LIB_NAME}.register(
    '#{@args[:attributes][:id]}',
    #{locations.to_json},
    #{map_options(context.registers[:site]).to_json}
  );
</script>
HTML
      end

      private
      def render_attributes
        attributes = []
        attributes << "id='#{@args[:attributes][:id]}'"
        attributes << render_dimensions
        attributes << render_class
        attributes.join(" ")
      end

      private
      def render_dimensions
        width       = @args[:attributes][:width] || DEFAULT_MAP_WIDTH
        height      = @args[:attributes][:height] || DEFAULT_MAP_HEIGHT
        width_unit  = width.to_s.include?("%") ? "" : "px"
        height_unit = height.to_s.include?("%") ? "" : "px"
        %(style='width:#{width}#{width_unit};height:#{height}#{height_unit};')
      end

      private
      def render_class
        css = @args[:attributes][:class]
        css = css.join(" ") if css.is_a?(Array)
        %(class='#{css} jekyll-map')
      end

      private
      def render_styles(site)
        style_name = @args[:attributes][:styles] || "default"
        maps_styles = site.data["maps_styles"] || {}
        maps_styles[style_name] || "[]"
      end

      private
      def map_options(site)
        opts = {
          :baseUrl         => site.baseurl || "/",
          :useCluster      => !@args[:flags][:no_cluster],
          :showMarker      => @args[:attributes][:show_marker] != "false",
          :showMarkerPopup => @args[:attributes][:show_popup] != "false",
          :markerIcon      => @args[:attributes][:marker_icon],
          :styles          => render_styles(site)
        }
        if @args[:attributes][:zoom]
          opts[:customZoom] = @args[:attributes][:zoom].to_i
        end
        opts
      end
    end
  end
end

Liquid::Template.register_tag("google_map", Jekyll::Maps::GoogleMapTag)
