SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON



-----------------------------------------------------------------------------------------
-- Fonction		: SPV_DECODEVALEURMISSION
-- Paramètre d'entrée	: @v_value : Chaîne de caractères codée
--			  @v_objet : Objet
-- Paramètre de sortie	: @v_str : Chaîne de caractères explicite
-- Descriptif		: Cette procédure décode une chaîne de caractères codée
--			  en une description explicite.
-----------------------------------------------------------------------------------------

CREATE FUNCTION [dbo].[SPV_DECODEVALEURMISSION] (@v_value varchar(100), @v_objet tinyint)
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
  declare @v_idTache int
  DECLARE
    @v_par_valeur varchar(128)

  -- déclaration des constantes
  declare @CHANGE_ETAT tinyint
  declare @EXECUTION_TACHE tinyint
  declare @AFFINAGE_TACHE tinyint
  declare @CHANGE_PRIORITE tinyint
  declare @CHANGE_ECHEANCE tinyint
  declare @TACHE_OK tinyint

  set @CHANGE_ETAT = 2
  set @CHANGE_PRIORITE = 3
  set @CHANGE_ECHEANCE = 4
  set @EXECUTION_TACHE = 7 
  set @AFFINAGE_TACHE = 20
  set @TACHE_OK = 0
 
  SELECT @v_par_valeur = PAR_VAL FROM PARAMETRE (NOLOCK) WHERE PAR_NOM = 'LANGUE'
  -- changement d'état Mission 
  if (@v_objet = @CHANGE_ETAT)
  begin 
    set @v_pos = charindex(';',@v_value)
    if (@v_pos <> 0)
    begin
      -- Récupération de l'état de la mission
      set @v_idEtat = substring(@v_value,1,@v_pos-1)
      set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

      select @v_str=isNull(LIB_Libelle,'') from ETAT_MISSION (NOLOCK)
      join TRADUCTION (NOLOCK) on (ETM_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where ETM_IdEtat=@v_idEtat
             
      set @v_pos = charindex(';',@v_value)
      if (@v_pos <> 0)
      begin
        -- Récupération de la raison du changement d'état
        set @v_dscEtat = substring(@v_value,1,@v_pos-1)
        set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos) 
      end
      
      select @v_str=@v_str+' - '+isNull(LIB_Libelle,'') from DESC_ETAT_TACHE (NOLOCK)
      join TRADUCTION (NOLOCK) on (DET_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where DET_DscEtat=@v_dscEtat
    end
  end
  -- changement d'exécution tâche
  else if (@v_objet = @EXECUTION_TACHE)
  begin
    set @v_pos = charindex(';',@v_value)
    if (@v_pos <> 0)
    begin
      -- Récupération de l'action de la tâche
      set @v_idAction = substring(@v_value,1,@v_pos-1)
      set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

      select @v_str=isNull(LIB_Libelle,'') from ACTION (NOLOCK)
      join TRADUCTION (NOLOCK) on (ACT_IdTraduction = TRA_Id) 
      join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
      where ACT_IdAction=@v_idAction

      set @v_pos = charindex(';',@v_value)
      if (@v_pos <> 0)
      begin
        -- récupération du code d'exécution de la tâche
        set @v_crdExec = substring(@v_value,1,@v_pos-1)
        set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

        if (@v_crdExec = @TACHE_OK)
          set @v_str=@v_str+' - '+'OK'
        else
           set @v_str=@v_str+' - '+'KO'

        set @v_pos = charindex(';',@v_value)
        if (@v_pos <> 0)
        begin
          -- récupération du détail d'exécution de la tâche
          set @v_detailExec = substring(@v_value,1,@v_pos-1)
          set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

          select @v_str=@v_str+' - '+isNull(LIB_Libelle,'') from DESC_ETAT_TACHE (NOLOCK)
          join TRADUCTION (NOLOCK) on (DET_IdTraduction = TRA_Id) 
          join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
          where DET_DscEtat=@v_detailExec
   
          set @v_pos = charindex(';',@v_value)
          if (@v_pos <> 0)
          begin
            -- récupération des infos relevées lors de l'exécution de la tâche
            set @v_infoExec = substring(@v_value,1,@v_pos-1)
            set @v_value = substring(@v_value,@v_pos+1,len(@v_value)-@v_pos)

            set @v_str=@v_str+' - '+@v_infoExec
          end
        end
      end
    end 
  end
  -- affinage tâche
  else if (@v_objet = @AFFINAGE_TACHE)
  begin
	select @v_idAction = @v_value
    select @v_str=isNull(LIB_Libelle,'') from ACTION (NOLOCK)
    join TRADUCTION (NOLOCK) on (ACT_IdTraduction = TRA_Id) 
    join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
    where ACT_IdAction=@v_idAction
  end
  -- changement priorité mission
  else if (@v_objet = @CHANGE_PRIORITE)
  begin
    select @v_str = @v_value
  end
  -- changement échéance mission
  else if (@v_objet = @CHANGE_ECHEANCE)
  begin
    select @v_str = @v_value
  end
  -- autres changements
  else
  begin
    select @v_str=isNull(LIB_Libelle,'') from DESC_ETAT_TACHE (NOLOCK)
    join TRADUCTION (NOLOCK) on (DET_IdTraduction = TRA_Id) 
    join LIBELLE (NOLOCK) on (LIB_Traduction = TRA_Id) and (LIB_Langue=@v_par_valeur)
    where DET_DscEtat=@v_value
  end

  return (@v_str)
end











