import shutil
import os


class PMCXML_FilesSet:

    def __init__(self, source_path, server_serial_path, img_path, pdf_path, xml_path, journal_folder, issue_folder, db_name):
        self.source_path = source_path + '/' + journal_folder + '/' + issue_folder + '/pmc'
        self.server_serial_path = server_serial_path + '/' + journal_folder + '/' + issue_folder 
        self.pdf_path = pdf_path + '/' + journal_folder + '/' + issue_folder
        self.img_path = img_path + '/' + journal_folder + '/' + issue_folder
        self.xml_path = xml_path + '/' + journal_folder + '/' + issue_folder

        self.package_path = self.source_path + '/pmc_package_source' 
        self.extracted_package_path = self.source_path + '/pmc_package_extracted' 
        
        self.db_path = self.server_serial_path + '/base' 
        
        self.db_name = db_name

        self.db_filename = self.db_path + '/' + db_name
        
        self.log_filename = self.db_path + '/' + db_name + '.log'
        self.err_filename = self.db_path + '/' + db_name + '.err.log'

        for f in [self.source_path, self.server_serial_path, self.pdf_path, self.img_path, self.xml_path, self.package_path, self.extracted_package_path, self.db_path, ]:
            if not os.path.exists(f):
                os.makedirs(f)
        
    def prepare_db_folder(self):
        self.delete_files_by_extension(self.db_path, ['.id', '.mst', '.xrf', '.log', ])
    

    def delete_db(self):
        self.delete_files_by_extension(self.db_path, [ '.mst', '.xrf' ])
    
    def archive(self, xml_filename):
        self.move_related_files(xml_filename)

        

    def copy_file_to_path(self, filename, dest_path):
        f = os.path.basename(filename)
        if not os.path.exists(dest_path):
            os.makedirs(dest_path)
        shutil.copyfile(filename, dest_path + '/' + f)
        return os.path.exists(dest_path + '/' + f)
    
    def copy_extracted_files_to_their_paths(self, xml_filename):
        count = 0
        f = os.path.basename(xml_filename).replace('.xml', '')
        path = os.path.dirname(xml_filename)
        matched_files = [ filename for filename in os.listdir(path) if f in filename ]
        for matched_file in matched_files:
            if self.copy_file_to_path(path + '/' + matched_file, self.extracted_package_path):
                count += 1
        return (count == len(matched_files))

    def move_file_to_path(self, filename, dest_path):
        f = os.path.basename(filename)
        if os.path.exists(dest_path + '/' + f):
            os.unlink(dest_path + '/' + f)
        if os.path.exists(filename):
            
            if not os.path.exists(dest_path):
                os.makedirs(dest_path)
    
            shutil.move(filename, dest_path)
        return os.path.exists(dest_path + '/' + f)
    
    def move_related_files(self, xml_filename):
        count = 0
        matched_count = 0
        for c in '-.':
            pattern = os.path.basename(xml_filename).replace('.xml', '') + c
            path = os.path.dirname(xml_filename)
            matched_files = [ filename for filename in os.listdir(path) if pattern in filename ]
            #matched_files.append(os.path.basename(xml_filename))
            matched_count += len(matched_files)
            for matched_file in matched_files:
            
                if self.move_file_to_path(path + '/' + matched_file, self.xml_path):
                    count += 1

        return (count == matched_count)

    def delete_files_by_extension(self, path, array_extension):
        if os.path.exists(path):
            files = os.listdir(path)
            for f in files:
                #print('deleting ' + path + '/' + f + '?')
                ext = f[f.rfind('.'):]
                if ext in array_extension:
                    #print('deleting ' + path + '/' + f)
                    os.remove(path + '/' + f)
        else:
            os.makedirs(path)
    
    