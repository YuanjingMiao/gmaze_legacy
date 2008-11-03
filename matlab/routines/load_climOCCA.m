% LOAD_CLIMOCCA Load any climatological fields from OCCA
%
% [FIELD1, FIELD2, ...] = LOAD_CLIMOCCA([FIELD1;FIELD2;...],MONTHS)
%
%
% Created by Guillaume Maze on 2008-10-14.
% Copyright (c) 2008 Guillaume Maze. 
% http://www.guillaumemaze.org/codes

%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    any later version.
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%


function varargout = load_climOCCA(varargin)
	
	
fields  = varargin{1};
Imonths = varargin{2};

if ischar(Imonths)
	switch lower(Imonths)
		case {'y';'year';'annual'}
			months = [1:12];
	end
else
	months = Imonths;
end


pathclim = '~/data/OCCA/clim/';
pathgrid = '~/data/OCCA/grid/';

REQUIREDfields = list2cell(fields);
nlon = 360; nlat = 160; ndpt = 50; recl = 4*nlon*nlat;

if nargout>size(REQUIREDfields,1)
	error('You ask for more than I can do for you !');
	return
end

for ifield = 1 : size(REQUIREDfields,1)
	fil = name2file(REQUIREDfields{ifield});
	fid_list(ifield) = fopen(strcat(pathclim,fil),'r','ieee-be');
end
[LSmask3D_0 LSmask3D_1 LSmask3D_2 LSmask3D_3] = load_mask(pathgrid);


for ifield = 1 : size(REQUIREDfields,1)
	clear C
	for ii = 1 : length(months)
		im = months(ii);
		[fil dime gridp] = name2file(REQUIREDfields{ifield});
		switch dime
			case 3
				fseek(fid_list(ifield),(im-1)*recl*ndpt,'bof');
				c = fread(fid_list(ifield),[nlon*nlat ndpt],'float32');
				c = reshape(c,nlon,nlat,ndpt); 
				c = permute(c,[3 2 1]);
				eval(['c=c.*LSmask3D_' num2str(gridp) ';']);
				C(ii,:,:,:) = c;
			case 2
				fseek(fid_list(ifield),(im-1)*recl,'bof');
				c = fread(fid_list(ifield),[nlon nlat],'float32');
				c = permute(c,[2 1]);
				eval(['c=c.*squeeze(LSmask3D_' num2str(gridp) '(1,:,:));']);
				C(ii,:,:) = c;
		end % switch dimensions
		clear c
	end %for ii
	eval([upper(REQUIREDfields{ifield}) '=C;']);	
end % for imonths
fclose('all');

if ischar(Imonths)
	for ifield = 1 : size(REQUIREDfields,1)
		switch lower(REQUIREDfields{ifield})
			case {'sst';'sss'}
				eval([upper(REQUIREDfields{ifield}) '=squeeze(nanmean(' upper(REQUIREDfields{ifield}) '(:,1,:,:),1));']);				
			otherwise
				eval([upper(REQUIREDfields{ifield}) '=squeeze(nanmean(' upper(REQUIREDfields{ifield}) '));']);
		end
	end
else
	for ifield = 1 : size(REQUIREDfields,1)
		switch lower(REQUIREDfields{ifield})
			case {'sst';'sss'}
				eval([upper(REQUIREDfields{ifield}) '=squeeze(' upper(REQUIREDfields{ifield}) '(:,1,:,:));']);				
			otherwise
				eval([upper(REQUIREDfields{ifield}) '=squeeze(' upper(REQUIREDfields{ifield}) ');']);
		end
	end
end

% OUTPUT:
if nargout >= 1
	for ifield = 1 : size(REQUIREDfields,1)
		eval(['varargout(ifield)={' upper(REQUIREDfields{ifield}) '};']);
	end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function REQUIREDfields = list2cell(tline);

tl = strtrim(tline);
if strmatch(';',tl(end)), tl = tl(1:end-1);end
tl = [';' tl ';']; pv = strmatch(';',tl');
for ifield = 1 : length(pv)-1
field(ifield).name = tl(pv(ifield)+1:pv(ifield+1)-1);
end
REQUIREDfields = squeeze(struct2cell(field));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
function varargout = name2file(varargin);
	
fieldname = varargin{1};
prefi = 'D';
suffi = '.0406clim.data';
gridp = 0; % Default


switch lower(fieldname)
	case {'theta';'sst'}, filename = 'Dtheta'; dime = 3;
	case {'salt';'sss'}, filename = 'Dsalt'; dime = 3;
	case {'eta';'ssh'}, filename = 'Detan'; dime = 2;
	case 'uvel', filename = 'Duvel'; dime = 3; gridp = 1;
	case 'vvel', filename = 'Dvvel'; dime = 3; gridp = 2;
	case {'kppmld';'mld'}, filename = 'KPPmld'; dime = 2;
	case {'emp','ep','snet'}, filename = 'FOsflux'; dime = 2;
	case {'q','qnet'}, filename = 'FOtflux'; dime = 2;
end

filename = strcat(prefi,filename,suffi);
switch nargout
	case 1
		varargout(1) = {filename};
	case 2
		varargout(1) = {filename};
		varargout(2) = {dime};
	case 3
		varargout(1) = {filename};
		varargout(2) = {dime};
		varargout(3) = {gridp};
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = load_mask(varargin);

path_grid = varargin{1};

iX = [1 360]; iY = [1 160]; iZ = [1 50];
nx = diff(iX)+1; ny = diff(iY)+1; nz = diff(iZ)+1;
iXg= [1:360 1]; iYg = [1:160 1]; iZg=[1:50+1];
iXg= [1:360 ]; iYg = [1:160 ]; iZg=[1:50];


fid    = fopen(strcat(path_grid,'maskCtrlC.data'),'r','ieee-be');
MASKCC = fread(fid,[nx*ny nz],'float32')'; fclose(fid);
MASKCC = reshape(MASKCC,[nz nx ny]); MASKCC = permute(MASKCC,[1 3 2]);

fid    = fopen(strcat(path_grid,'maskCtrlS.data'),'r','ieee-be');
MASKCS = fread(fid,[nx*ny nz],'float32')'; fclose(fid);
MASKCS = reshape(MASKCS,[nz nx ny]); MASKCS = permute(MASKCS,[1 3 2]);

fid    = fopen(strcat(path_grid,'maskCtrlW.data'),'r','ieee-be');
MASKCW = fread(fid,[nx*ny nz],'float32')'; fclose(fid);
MASKCW = reshape(MASKCW,[nz nx ny]); MASKCW = permute(MASKCW,[1 3 2]);

LSmask3D   = MASKCC(iZ(1):iZ(2),iY(1):iY(2),iX(1):iX(2));
LSmask3D_u = MASKCW(iZ(1):iZ(2),iY(1):iY(2),iXg);
LSmask3D_v = MASKCS(iZ(1):iZ(2),iYg,iX(1):iX(2));
c = MASKCC; c = cat(1,c,zeros(1,ny,nx));
LSmask3D_w = c(iZg,iY(1):iY(2),iX(1):iX(2));

LSmask3D(LSmask3D==0) = NaN;
LSmask3D_u(LSmask3D_u==0) = NaN;
LSmask3D_v(LSmask3D_v==0) = NaN;
LSmask3D_w(LSmask3D_w==0) = NaN;


varargout(1) = {LSmask3D};
varargout(2) = {LSmask3D_u};
varargout(3) = {LSmask3D_v};
varargout(4) = {LSmask3D_w};



























