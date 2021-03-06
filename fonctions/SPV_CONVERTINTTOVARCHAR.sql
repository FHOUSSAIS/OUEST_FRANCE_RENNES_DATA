SET ANSI_NULLS OFF
SET QUOTED_IDENTIFIER OFF



-----------------------------------------------------------------------------------------
-- Fonction		: SPV_CONVERTINTTOVARCHAR
-- Paramètre d'entrée	: @vp_num : Entier a convertir en chaine de caractères
--			  @vp_len : taille de la chaine de caractères de retour	
-- Paramètre de sortie	: Entier convertit en chaine de caractères.
-- Descriptif		: Cette procédure convertit un entier en chaine de caractères de longeur voulue.
--			  Des 0 sont ajoutés en début de chaine pour obtenir la longueur voulue.
-----------------------------------------------------------------------------------------
-- Révisions	
-----------------------------------------------------------------------------------------
-- Date			: 28/06/2005 									
-- Auteur		: M. Crosnier
-- Libellé			: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_CONVERTINTTOVARCHAR] (@vp_num int,@vp_len int)
	RETURNS varchar(120)
AS
begin
--déclaration des variables
declare @v_lenNum int
declare @v_strNum varchar(120)
declare @v_string varchar(120)

set @v_strNum = CONVERT(varchar, @vp_num)
set @v_lenNum = LEN(@v_strNum)
if (@v_lenNum >= @vp_len)
begin
  -- L'entier a codé est plus grand que la longueur demandée, on retourne la chaine contenant l'entier
  set @v_string = @v_strNum
end
else begin
  -- On ajoute des 0 en début de chaine pour avoir la longueur voulue
  set @v_string = REPLICATE('0', @vp_len-@v_lenNum) + @v_strNum
end

return @v_string
end









