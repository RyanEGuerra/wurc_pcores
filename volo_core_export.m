% Internal VOLO pcore export tool
% Copies the generated pcore into the appropriate svn repo trunk directory and packs in
% all relevant files. (makes mdlsrc directory).

% TODO: Make sure this works on linux with its different filepath conventions

% NOTE ** The pcore generation directory must be *generated_pcores (AND NO OTHER DIRECTORY
% CAN BE NAMED THIS)

clear all

% Private Pcore export directory
export_dir_private = '../pcore_private/pcores/';

% EXPORT FILE TYPES
% -- Cell array of export file type identifiers to export (handle '*.mdl', '*.slx'
% separately)
export_file_types = {'*.m', '*.cdc', '*.mat', '*.v', '*.vhdl', '*.csv'};
% ** NOTE: Everything in the /etc/ folder will be copied as 

% Local Setup initialization file name
% -- uses the inifile.m utility in the WARP repo
% -- Inifile MUST be in the same directory of this script. Do NOT check this inifile in!
ini_fileName = './volo_dev_export.ini';

%% If this initialization file doesn't exist, prompt user to create it
if(~exist(ini_fileName, 'file'))
    disp([' -- INI FILE <' ini_fileName '> NOT FOUND -- '])
    disp('    Creating initialization file ... ')
    disp('      -> Select the destination pcore library folder in the svn repo.. ')
    folder_name = uigetdir('./', 'Select destination pcore library folder');
    % Append the trailing \ if it isnt already there
    if(~strcmp(folder_name(end), '\'))
        folder_name = [folder_name '\'];
    end
    disp(['   Folder path selected! ->' folder_name])
    disp(' Writing initialization file ... ')
    inifile(ini_fileName, 'new')
    write_keys = {'pcore_export_info', '', 'dir',  folder_name};
    inifile(ini_fileName, 'write', write_keys, 'tabbed')
else
   disp(' -- inifile found!! --') 
end

%% Now that inifile either exists or has just been created, perform export

% Get export directory
read_keys = {'pcore_export_info', '', 'dir', ''};
export_dir_public = inifile(ini_fileName, 'read', read_keys);
export_dir_public = export_dir_public{1};
if(length(export_dir_public)<3)
    if(exist(ini_fileName, 'file'))
        delete(ini_fileName)
    end
    error('No pcore export path chosen!')
end
% Get list of all "dev" sysgen folders
dev_list = dir('./*dev*');
dev_folder = {};
for i=1:length(dev_list)
    if(dev_list(i).isdir==1)
        dev_folder = [dev_folder dev_list(i).name];
    end
end

% Prompt for public or private export
disp(' -- Select Public or private export destination -- ')
disp(['   (1) Private: <' export_dir_private '>'])
disp(['   (2) Public:  <' export_dir_public '>'])
while(1)
    idx = str2num(input('<> Select export dir: ', 's'));
    if(length(idx) == 1)
        if(1<= idx && idx <= 2)
            break;
        end
    end
    disp('   !! Invalid selection !!   ') 
end
disp(' ***** ***** ***** ')
if(idx==1)
    export_dir = export_dir_private;
    strname = '--PRIVATE--';
elseif(idx==2)
    export_dir = export_dir_public;
    strname = '--PUBLIC--';
else
    error(' WTF how did you get here?')
end
disp(['  Selected: ' strname 'at <' export_dir '>']);
% Prompt for the pcore
disp( ' -- Select pcore to export -- ')
for i=1:length(dev_folder)
   disp(['    (' num2str(i) ') -> ' dev_folder{i}]) 
end
while(1)
    idx = str2num(input('<> Select pcore: ', 's'));
    if(length(idx) == 1)
        if(1<= idx && idx <= length(dev_folder))
            break;
        end
    end
    disp('   !! Invalid selection !!   ') 
end
disp(' ***** ***** ***** ')
pcore_sel = dev_folder{idx};
disp([' -- Selected: <' pcore_sel '>'])

%% Begin Export process
% First, find and save the mdl or slx file
flist = [dir(['./' pcore_sel '/*.mdl']) dir(['./' pcore_sel '/*.slx'])];
disp(' -- Saving the sysgen models ...')
for i=1:length(flist)
    mdl_name = ['./' pcore_sel '/' flist(i).name];
    disp(['   Currently saving: <' mdl_name '>'])
   save_system(mdl_name);
   mdl_name_arr{i} = flist(i).name;
end

%% Now, find the latest generated pcore
flist = dir(['./' pcore_sel '/*generated_pcores']);
cdc_list = dir(['.\' pcore_sel '\' flist.name '\*.cdc']);
cdc_file = ['.\' pcore_sel '\' flist.name '\' cdc_list.name];
gen_pcore_path = ['./' pcore_sel '/' flist(1).name '/pcores/'];
flist = dir([gen_pcore_path '*w*']); % Pcore will always have w in the name (axiw or plbw) -- HACK!
% [val, idx] = sort([flist.datenum], 'descend'); % !! DOESNT WORK IF YOU JUST DID A CHECKOUT OR SOMETHING
gen_pcore_name = flist(end).name; % The last item in list is the highest version number (I think)
gen_pcore_loc = [gen_pcore_path  gen_pcore_name '/'];
% Prompt user if this is correct
disp([' -- Latest Pcore is: <' gen_pcore_loc '>'])
str = input( '   Is this correct? <y,n> : ', 's');
if(~strcmp(str, 'Y') && ~strcmp(str, 'y'))
   disp(' ** ok then Im quitting, bye ')
   return;
end

%% Double-check to see if all of the memory offset definitions in the MPD are unique
% Added by Ryan to try and detect/correct overlapping memory problems with
% the damned EDK Processor
% 05/26/2014 - Realized that it was register read-back that was not being
% re-checked when the EDK Processor was being replaced. Now this just
% checks to make sure there are no dups; but to really be correct it should
% check for register readback being enabled in the mdl file. REG
mpd_file = dir([gen_pcore_loc 'data/*.mpd']);
mpd_path = [gen_pcore_loc 'data/' mpd_file.name];
off_pattern = '0x[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f],';
observed_addrs = [];
% test for duplicates
mpd_fid = fopen(mpd_path);
    tline = fgets(mpd_fid);
    while ischar(tline)
        if strncmpi('PARAMETER', tline, 9)
            toks = strread(tline, '%s', 'delimiter', ' ');
            offset = regexp(toks(4), off_pattern, 'match');
            % doesn't match... check next line
            if ~isempty(offset{1})
                offset = offset{1};
                offset = offset{1};
                offset = offset(3:5);
                %disp(['FOUND: ' offset ', dec: ' num2str(hex2dec(offset))]);
                observed_addrs = [observed_addrs, hex2dec(offset)];
            end
        end
        % get next line
        tline = fgets(mpd_fid);
    end
fclose(mpd_fid);
% prompt for correcting the file...
if (length(observed_addrs) ~= length(unique(observed_addrs)))
    disp(' -- Duplicate offset addresses found in MPD!');
    disp('    CHECK EDK PROCESSOR FOR "ALLOW READBACK" AND TRY AGAIN!');
    return;
%     str = input( '    Would you like to re-map offsets? <y/n> : ', 's');
%     if(~strcmp(str, 'Y') && ~strcmp(str, 'y'))
%        disp(' ** since the pcore is useless, Im quitting. bye ')
%        return;
%     end
%     % output file
%     out_path = [mpd_path '.new'];
%     % The memory offsets of pcores all appear to start at 0x800
%     % and we post-increment by 4
%     next_offset = hex2dec('800');
%     % overwrite memory offsets with new values
%     mpd_fid = fopen(mpd_path, 'r');
%     out_fid = fopen(out_path, 'w+');
%         tline = fgets(mpd_fid);
%         while ischar(tline)
%             if strncmpi('PARAMETER', tline, 9)
%                 toks = strread(tline, '%s', 'delimiter', ' ');
%                 offset = regexp(toks(4), off_pattern, 'match');
%                 % doesn't match... check next line
%                 if ~isempty(offset{1})
%                     %TODO: print modified line
%                     fprintf(out_fid, '%s %s %s 0x%s,',...
%                         toks{1}, toks{2}, toks{3}, dec2hex(next_offset));
%                     for ii = 5:length(toks)
%                         fprintf(out_fid, ' %s', toks{ii});
%                     end
%                     fprintf(out_fid, '\r\n');
%                     next_offset = next_offset + 4;
%                 else
%                     % print string normally
%                     fprintf(out_fid, '%s', tline);
%                 end
%             else
%                 % print string normally
%                 fprintf(out_fid, '%s', tline);
%             end
%             % get next line
%             tline = fgets(mpd_fid);
%         end
%     fclose(out_fid);
%     fclose(mpd_fid);
%     % rename files to save old mpd file and place new one in it's place
%     bak_path = [mpd_path '.bak'];
%     disp(' -- remapped AXI configuration registers to non-overlapping values');
%     disp(['    original file saved in: <' bak_path '>']);
%     movefile(mpd_path, bak_path);
%     movefile(out_path, mpd_path);
end

%% Copy the latest generated pcore into the export directory
disp(' -- Beginning export process')
disp('   Copying pcore...')
dst_dir = [export_dir gen_pcore_name '/'];
if(exist(dst_dir, 'dir'))
    rmdir(dst_dir, 's') % Delete existing directory
end
[status, mess, messid] = copyfile(gen_pcore_loc, dst_dir, 'f');
if(status==0)
    disp(' !! COPY ERROR !!')
    mess
    messid
    return;
end
% Create the mdlsrc directory
mdlsrc_dir = [dst_dir 'mdlsrc/'];
% Copy the etc folder
if(exist(['./' pcore_sel '/etc/'], 'dir'))
    copyfile(['./' pcore_sel '/etc/'], [mdlsrc_dir 'etc/'], 'f')
else
    mkdir(mdlsrc_dir)
end
% Ryan's hack to add CDC export
try
    copyfile(cdc_file, [mdlsrc_dir '.\' cdc_list.name]);
catch any_err
    disp(['Error copying: ' mdlsrc_dir '.\' cdc_list.name]);
end
% Copy all of the filetypes that we care about
copy_list = {};
for i=1:length(export_file_types)
   flist = dir(['./' pcore_sel '/' export_file_types{i}]);
   for j=1:length(flist)
       copy_list = [copy_list flist(j).name];
   end
end
for i=1:length(copy_list)
   copyfile(['./' pcore_sel '/' copy_list{i}], mdlsrc_dir, 'f') 
end

%% Now copy over th mdl/slx file but append it with the pcore version number
% - get version number
splitName = regexp(gen_pcore_name, '_', 'split');
splitName = splitName(end-2:end);
toAppend = ['_' splitName{1} '_' splitName{2} '_' splitName{3}];
for i=1:length(mdl_name_arr)
   fullN = mdl_name_arr{i};
   name = fullN(1:end-4);
   type = fullN(end-2:end);
   src = ['./' pcore_sel '/' fullN];
   dst = [mdlsrc_dir name toAppend '.' type];
   copyfile(src, dst, 'f')
end

disp(' ** FINISHED!! **')
