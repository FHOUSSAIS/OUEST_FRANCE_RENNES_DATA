SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON




-----------------------------------------------------------------------------------------
-- Fonction		: SPV_DECODEVALEURORDREAGV
-- Paramètre d'entrée	: @v_value : Chaîne de caractères codée
--			  @v_objet : Objet
-- Paramètre de sortie	: @v_str : Chaîne de caractères explicite
-- Descriptif		: Cette procédure décode une chaîne de caractères codée
--			  en une description explicite.
-----------------------------------------------------------------------------------------
-- Révisions	
-----------------------------------------------------------------------------------------
-- Date			: 01/11/2004
-- Auteur		: S.Loiseau
-- Libellé			: Création de la procédure
-----------------------------------------------------------------------------------------
-- Date			: 07/06/2005									
-- Auteur		: S.Loiseau									
-- Libellé			: Modification de la fonction suite au multilangue					
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_DECODEVALEURORDREAGV] (@v_value varchar(100),@v_objet tinyint)
	RETURNS varchar(1000)
AS
begin
  -- déclaration des variables
  declare @v_idEtat tinyint
  declare @v_dscEtat tinyint
  declare @v_detailExec tinyint
  declare @v_str varchar(1000)
  declare @v_pos integer
  declare @v_crdExec bit
  declare @v_idAction integer
  declare @v_infoExec varchar(100)
  DECLARE
    @v_par_valeur varchar(128)

  -- déclaration des constantes
  declare @CHANGE_ETAT tinyint
  declare @EXECUTION_TACHE tinyint
  declare @TACHE_OK tinyint

  set @CHANGE_ETAT = 2
  set @EXECUTION_TACHE = 7 
  set @TACHE_OK = 0
 
  SELECT @v_par_valeur = PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'
  -- changement d'état Mission --
  if (@v_objet = @CHANGE_ETAT)
  begin 
    set @v_pos = charindex(';',@v_value)
    if (@v_pos <> 0)
    begin
      -- Récupération de l'état de l'ordre
      set @v_idEtat = substring(@v_value,1,@v_pos-1)
      set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

      select @v_str=isNull(LIB_Libelle,'') from ETAT_ORDRE (NOLOCK)
      join TRADUCTION (NOLOCK) on (ETO_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where ETO_IdEtat=@v_idEtat
           
      set @v_pos = charindex(';',@v_value)
      if (@v_pos <> 0)
      begin
        -- Récupération de la raison du changement d'état
        set @v_dscEtat = substring(@v_value,1,@v_pos-1)
        set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos) 
      end
      
      select @v_str=@v_str+' - '+isNull(LIB_Libelle,'') from DESC_ETAT_ORDRE (NOLOCK)
      join TRADUCTION (NOLOCK) on (DEO_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where DEO_DscEtat=@v_dscEtat
    end
  end
  else 
  begin
    select @v_str=isNull(LIB_Libelle,'') from DESC_ETAT_ORDRE (NOLOCK)
    join TRADUCTION (NOLOCK) on (DEO_IdTraduction = TRA_Id) 
    join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
    where DEO_DscEtat=@v_value
  end

  return (@v_str)
end












