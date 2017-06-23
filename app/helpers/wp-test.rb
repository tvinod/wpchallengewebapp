require 'rest-client'
require 'json'
require 'set'

$wp_base_30 = "http://proapi.whitepages.com/3.0/"
$wp_base_22 = "http://proapi.whitepages.com/2.2/entity/"
$api_key = "api_key=c5ec1bbbc3394afb991ce53e1ad2c7c8"

module WpTest
  def my_test
    'hello world'
  end

  def find_person(name, city, state_code)
    person_search_request = $wp_base_30 + "person.json?" + $api_key +
    "&name=" + (name.sub ' ','+') + "&address.city=" + city +
      "&address.state_code=" + state_code
      puts "calling rest endpoint #{person_search_request}"
      person_search_response = RestClient.get person_search_request
      person_json = JSON.parse(person_search_response.body, :symbolize_names => true)
      ret_person = nil
      person_json[:person].each do |person|
        ret_person = person
        break
      end

      return ret_person
  end

  def find_person_ids(name, city, state_code)
    person_search_request = $wp_base_30 + "person.json?" + $api_key +
        "&name=" + (name.sub ' ','+') + "&address.city=" + city +
        "&address.state_code=" + state_code
    puts "calling rest endpoint #{person_search_request}"
    person_search_response = RestClient.get person_search_request
    person_json = JSON.parse(person_search_response.body, :symbolize_names => true)
    ret_ids = Set.new
    person_json[:person].each do |person|
      ret_ids << person[:id]
    end

    return ret_ids
  end

  def load_from_api(node_type, id)
    url = $wp_base_22 + id + ".json?" + $api_key
    puts "calling rest endpoint #{url}"
    ret_obj_response = RestClient.get url
    ret_obj = JSON.parse(ret_obj_response, :symbolize_names => true)
    return ret_obj
  end


  def get_relation(p1_name, p1_city, p1_state_code, p2_name, p2_city, p2_state_code)

      from_name = p1_name
      from_city = p1_city
      from_state_code = p1_state_code
      to_name = p2_name
      to_city = p2_city
      to_state_code = p2_state_code

      from_person = find_person(from_name, from_city, from_state_code)
      to_person_ids = find_person_ids(to_name, to_city, to_state_code)

      queue = Queue.new
      from_node = Hash.new
      from_node[:node_type] = "person"
      from_node[:id] = from_person[:id]
      from_node[:entity] = from_person
      from_node[:loaded] = true
      from_node[:path] = Array.new << from_node
      queue << from_node
      queue << from_person
      set = Set.new

      path_found = Queue.new
      while !queue.empty?() do
          current_node = queue.pop
          puts "dequeued #{current_node[:id]}"
          if (set.include?(current_node[:id]))
            next
          end
          set.add(current_node[:id])
          if (!current_node[:path].nil? && current_node[:path].length >= 5)
            puts "path is already 5 or more. not fanning out any more"
            next
          end
          if (!current_node[:loaded])
            puts "loading #{current_node}"
            current_node[:entity] = load_from_api(
              current_node[:node_type], current_node[:id])
            current_node[:loaded] = true
          end
          if (current_node[:node_type].eql?("person"))
            if (to_person_ids.include?(current_node[:id]))
              path_found = current_node[:path]
              break
            end
              current_person = current_node[:entity]
              associated_people = current_person[:associated_people]
              if (!associated_people.nil?)
                  associated_people.each do |associated_person|
                      if (set.include?(associated_person[:id]))
                        next
                      end
                      associated_person_id = associated_person[:id]
                      puts "associated person is #{associated_person}"
                      new_node = Hash.new
                      new_node[:node_type] = "person"
                      new_node[:id] = associated_person[:id]
                      new_node[:entity] = associated_person
                      new_node[:path] = Array.new(current_node[:path])
                      new_node[:path] << new_node
                      new_node[:loaded] = false
                      if (to_person_ids.include?(associated_person_id))
                        path_found = new_node[:path]
                        break
                      end
                      puts "enqueuing associated person #{associated_person[:id]}"
                      queue << new_node
                  end
              end
              if (!path_found.empty?)
                break
              end
              addresses = Array.new
              if (!current_person[:current_addresses].nil?)
                addresses << current_person[:current_addresses]
              end
              if (!current_person[:historical_addresses].nil?)
                addresses << current_person[:historical_addresses]
              end
              if (!current_person[:results].nil? && !current_person[:results].empty?)
                current_person[:results].compact!
              end

              if (!current_person[:results].nil? && !current_person[:results].empty?)

                current_person[:results].each do |person_result|
                  if (!person_result[:locations].nil?)
                    addresses << person_result[:locations]
                  end
                end
              end
              addresses.flatten!
              # need to handle 2.2 response for person also.. IMP!!
              addresses.each do |address|
                id = nil
                entity = nil
                if (address[:id].class != Hash)
                  id = address[:id]
                else
                  id = address[:id][:key]
                end
                puts "address is #{id}"


                if (set.include?(id))
                  puts "skipping address #{id} since already in set"
                  next
                end
                new_node = Hash.new
                new_node[:node_type] = "location"
                new_node[:id] = id
                new_node[:entity] = address
                new_node[:path] = Array.new(current_node[:path])
                new_node[:path] << new_node
                new_node[:loaded] = false
                puts "enqueuing address #{id}"
                queue << new_node
              end
              if (!current_person['phones'].nil?)
                current_person['phones'].each do |phone|
                  if (set.include?(phone[:id]))
                    next
                  end
                  puts "phone is #{phone}"
                  new_node = Hash.new
                  new_node[:node_type] = "phone"
                  new_node[:id] = phone[:id]
                  new_node[:entity] = phone
                  new_node[:path] = Array.new(current_node[:path])
                  new_node[:path] << new_node
                  new_node[:loaded] = false
                  puts "enqueuing phone #{phone[:id]}"
                  queue << new_node
                end
              end
          end
          if (current_node[:node_type].eql?("location"))
              location_entity = current_node[:entity]

              if (!location_entity[:results].nil? && !location_entity[:results].empty?)

                location_entity[:results].compact!

                location_entity[:results].each do |location_person_result|

                  legal_entities_at = location_person_result[:legal_entities_at]
                  if (!legal_entities_at.nil?)
                    legal_entities_at.each do |legal_entity_person|
                      if (set.include?(legal_entity_person[:id][:key]))
                        next
                      end
                      new_node = Hash.new
                      new_node[:node_type] = "person"
                      new_node[:id] = legal_entity_person[:id][:key]
                      new_node[:entity] = legal_entity_person
                      new_node[:path] = Array.new(current_node[:path])
                      new_node[:path] << new_node
                      new_node[:loaded] = false
                      puts "enqueuing person #{new_node[:id]}"
                      queue << new_node
                    end
                  end
                end
              end
          end

          if (current_node[:node_type].eql?("phone"))
              phone_entity = current_node[:entity]
              path_so_far = current_node[:path] << current_node[:entity]
              belongs_to = phone_entity[:belongs_to]
              belongs_to.each do |belongs_to_person|
                if (set.include?(belongs_to_person[:id][:key]))
                  next
                end
                new_node = Hash.new
                new_node[:node_type] = "person"
                new_node[:id] = belongs_to_person[:id][:key]
                new_node[:entity] = belongs_to_person
                new_node[:path] = Array.new(current_node[:path])
                new_node[:path] << new_node
                new_node[:loaded] = false
                puts "enqueuing person #{new_node[:id]}"
                queue << new_node
              end
          end
      end

      if (path_found.empty?)
        puts "no path found :("
        ret_str = "no path found :("
        return ret_str
      end

      puts "printing path"
      prev_entity = nil
      prev_entity_str = ""
      ret_str = ""
      path_found.each_with_index do |path_element, index|
        puts "#{path_element[:id]}"
        if (index == 0)
          prev_entity_str = "#{path_element[:entity][:name]}"
          prev_entity = path_element
          next
        end
        if (path_element[:node_type].eql?("location"))
          location_str = path_element[:entity][:results][0][:standard_address_line1] + " " + path_element[:entity][:results][0][:city] + " " +
              path_element[:entity][:results][0][:state_code]
          ret_str = ret_str + prev_entity_str + " lives at " + location_str + "\n"
          prev_entity_str = location_str
          prev_entity = path_element
          next
        end

        if (path_element[:node_type].eql?("phone"))
          phone_str = path_element[:entity][:results][0][:phone_number]
          ret_str = ret_str + prev_entity_str + " has a phone number " + phone_str + "\n"
          prev_entity_str = phone_str
          prev_entity = path_element
          next
        end

        if (path_element[:node_type].eql?("person"))
          person_name = ""
          if (path_element[:loaded])
            person_name = path_element[:entity][:results][0][:names][0][:first_name] + " " + path_element[:entity][:results][0][:names][0][:last_name]
          else
            person_name = path_element[:entity][:name]
          end
          if (prev_entity[:node_type].eql?("location") )
            ret_str = ret_str + person_name + " lives at " + prev_entity_str + "\n"
            prev_entity_str = person_name
            prev_entity = path_element
            next
          end
          if (prev_entity[:node_type].eql?("person"))
            ret_str = ret_str + prev_entity_str + " is associated to " + "#{person_name}\n"
            prev_entity = path_element
            prev_entity_str = person_name
            next
          end
          if (prev_entity[:node_type].eql?("phone") )
            ret_str = ret_str + person_name + " has the phone number " + prev_entity_str + "\n"
            prev_entity_str = person_name
            prev_entity = path_element
            next
          end
        end

      end

    return ret_str
  end

end