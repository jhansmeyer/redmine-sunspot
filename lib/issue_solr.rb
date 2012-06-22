
module IssueSolr
  def self.included(base) # :nodoc:
  base.extend(ClassMethods)
  
    # Same as typing in the class
    base.class_eval do
      
      def attachments_fulltext
        text = ""
        attachments.map do |attachement| 
          if File.exists? attachement.diskfile
		command = "java -jar '#{Rails.root}/vendor/plugins/redmine_index_attachments/java/tika-app-1.1.jar' --text '#{attachement.diskfile}'"
            text += `#{command}`
            logger.error( command + " returns " + $?.exitstatus.to_s ) unless $?.exitstatus == 0
          end
        end
        return text
       end

      searchable do
        text :attachments_fulltext
        integer :id
        integer :project_id
        date :created_on
      end
    end
  end
    
  module ClassMethods
    
    def search(tokens, projects=nil, options={})
      
      database_results, c = super
 
 #
 # => For titles_only, skip fulltext search
 #
      if options[:titles_only]
        return [database_results, c ]
      end
      
#
# => Limit search to required project(s)
#
      if projects.is_a? Project
           
          fulltext_search = Sunspot.search( Issue ) do
            keywords tokens
              with :project_id, projects.id
          end
          
      elsif projects.is_a? Array
        
          fulltext_search = Sunspot.search( Issue ) do
            keywords tokens
              with(:project_id).any_of( projects.collect { |project| project.id } )
          end

      else
        
          fulltext_search = Sunspot.search( Issue ) do
            keywords tokens
          end
      end
      
      fulltext_results = fulltext_search.results
      
      

 #
 # => Merge database_results and fulltext_results accoding to :offset and :before
 #
      if fulltext_results.is_a? Array
        hash = Hash[database_results.map { |issue| [issue.id, issue] }]
        hash = hash.merge(Hash[fulltext_results.map { |issue| [issue.id, issue] }])
        
        temp = hash.values
                         
        if options[:before]
        
          if options[:offset]
            temp.delete_if { |issue| issue.created_on > options[:offset] }
          end
          results = temp.sort { |a,b| b.created_on <=> a.created_on }
        else
          
         if options[:offset]
            temp.delete_if { |issue| issue.created_on < options[:offset] }
          end
          results = temp.sort { |a,b| b.created_on <=> a.created_on }
          
        end
      else
        results = database_results
      end
     
      [results.slice(0,options[:limit]), c + fulltext_results.length ]
      
    end
 
  end
  
end
