SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON


-----------------------------------------------------------------------------------------
-- Procédure		: SPV_EXTRAITTRACEMISSION
-- Paramètre d'entrée	: @v_dateTrace : Date des traces à extraire
-- Paramètre de sortie	: Code de retour par défaut :
--			    - @CODE_OK : L'extraction s'est exécutée correctement
--			    - @CODE_KO_SQL : Une erreur s'est produite lors de l'extraction. 
--			  Dès lors qu'une erreur se produit, la procédure est interrompue
--			  à l'endroit du problème et le fichier créé est vide
-- Descriptif		: Extrait de la table TRACE_MISSION toutes les missions de transfert de
--			  charge et préformate ces traces afin de les rendre compatibles avec 
--			  l'analyseur de production
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_EXTRAITTRACEMISSION]
	@v_dateTrace dateTime
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- déclaration des variables
declare @v_codeRetour integer
declare @v_idMission integer
declare @v_idMissionPrec integer
declare @v_idMissionCrt integer
declare @v_idDemande varchar(20)
declare @v_idDemandeCrt varchar(20)
declare @v_dateEcriture dateTime
declare @v_dateOperation dateTime
declare @v_dateCreation dateTime
declare @v_dateAttribution dateTime
declare @v_datePrise dateTime
declare @v_dateDepose dateTime
declare @v_typeTrace integer
declare @v_strTrace varchar(1000)
declare @v_detail varchar(50)
declare @v_idCharge int
declare @v_idChargeCrt int
declare @v_typeMissionCrt tinyint
declare @v_adrSys bigint
declare @v_adrBase bigint
declare @v_adrSsBase bigint
declare @v_adrAttribution bigint
declare @v_adrPrise bigint
declare @v_adrDepose bigint
declare @v_idAgv tinyint
declare @v_idAgvCrt tinyint
declare @v_pos integer
declare @v_idEtat tinyint
declare @v_idAction integer
declare @v_crdExec bit

-- déclaration des constantes code retour
declare @CODE_OK tinyint
declare @CODE_KO_SQL tinyint

-- déclaration constante état mission
declare @ID_ETAT_ENCOURS tinyint

-- déclaration constante action tâche
declare @ACTION_PRISE tinyint
declare @ACTION_DEPOSE tinyint

-- déclaration constante compte-rendu d'exécution tâche
declare @TACHE_OK tinyint

-- déclaration des constantes type trace 
declare @CREATION tinyint                 -- Création mission
declare @CHANGE_PRIORITE tinyint          -- Changement de la priorité d'une mission
declare @CHANGE_DATEECHEANCE tinyint      -- Changement de la date d'échéance d'une mission
declare @CHANGE_ETAT tinyint              -- Changement d'état d'une mission
declare @ANNULATION tinyint               -- Annulation d'une mission
declare @FIN tinyint                      -- Fin d'une mission
declare @EXECUTION_TACHE tinyint          -- Exécution d'une tâche mission
declare @DESTRUCTION tinyint		  -- Destruction mission	

-- définition des constantes
set @CREATION            = 1
set @CHANGE_ETAT         = 2
set @CHANGE_PRIORITE     = 3
set @CHANGE_DATEECHEANCE = 4
set @ANNULATION          = 5
set @FIN                 = 6
set @EXECUTION_TACHE     = 7
set @DESTRUCTION         = 8
set @CODE_OK             = 0
set @CODE_KO_SQL         = 13
set @ID_ETAT_ENCOURS     = 2
set @TACHE_OK            = 0
set @ACTION_PRISE        = 2
set @ACTION_DEPOSE       = 4


-- intialisation des variables
set @v_codeRetour = @CODE_OK 
set @v_idMissionPrec = 0


-- déclaration de la variable de type table
declare @v_trace table ([TMT_CHAINE] [varchar] (1000)) 

-- récupération des identifiants de mission de transfert charge terminées dans la journée
declare c_selectMission CURSOR LOCAL for
select TMI_IdMission from TRACE_MISSION 
where (day(TMI_Date)=day(@v_dateTrace)) and (month(TMI_Date)=month(@v_dateTrace))and(year(TMI_Date)=year(@v_dateTrace))
and(TMI_TypeTrc = @FIN) and (TMI_IdCharge is Not NULL)
order by TMI_Id

-- ouverture du curseur de sélection des missions
open c_selectMission
fetch next from  c_selectMission INTO @v_idMissionCrt
while (@@FETCH_STATUS = 0)
begin
  set @v_idMission = NULL
  set @v_idDemande = NULL
  set @v_dateCreation = NULL
  set @v_dateAttribution = NULL
  set @v_datePrise =  NULL
  set @v_dateDepose =  NULL
  set @v_dateEcriture =  NULL
  set @v_idCharge = NULL
  set @v_idAgv = NULL
  set @v_adrAttribution = NULL
  set @v_adrPrise = NULL
  set @v_adrDepose = NULL
  set @v_strTrace = NULL

  -- pour chaque mission terminée, récupération de toutes les informations relatives à la mission  
  declare c_selectInfoMission CURSOR LOCAL for
  select TMI_Date,TMI_TypeTrc,TMI_DscTrc,TMI_IdDemande,TMI_IdCharge,TMI_AdrSys,TMI_AdrBase,TMI_AdrSsBase,TMI_IdAgv
  from TRACE_MISSION 
  where (TMI_IdMission=@v_idMissionCrt)

  -- ouverture du curseur de sélection des info missions
  open c_selectInfoMission
  fetch next from  c_selectInfoMission INTO @v_dateOperation,@v_typeTrace,@v_detail,@v_idDemandeCrt,
                                            @v_idChargeCrt,@v_adrSys,@v_adrBase,@v_adrSsBase,@v_idAgvCrt
  while (@@FETCH_STATUS = 0)
  begin
    --------------------------------------------------------
    --                  TRACE CREATION                    --
    --------------------------------------------------------      
    if (@v_typeTrace = @CREATION)
    begin
      set @v_idMission=@v_idMissionCrt
      set @v_idDemande=@v_idDemandeCrt
      set @v_dateCreation=@v_dateOperation
      set @v_idCharge=@v_idChargeCrt
    end
    --------------------------------------------------------
    --                  TRACE ATTRIBUTION                 --
    -------------------------------------------------------- 
    else if (@v_typeTrace = @CHANGE_ETAT)
    begin
      -- récupération de l'état de la mission
      set @v_pos = charindex(';',@v_detail)
      if (@v_pos <> 0)
      begin
        set @v_idEtat = substring(@v_detail,1,@v_pos-1)
        if (@v_idEtat = @ID_ETAT_ENCOURS)
        begin
          set @v_dateAttribution = @v_dateOperation
          set @v_adrAttribution = @v_adrBase
          set @v_idAgv = @v_idAgvCrt
        end
      end
    end    
    --------------------------------------------------------
    --                   TRACE COMPTE-RENDU PRISE         --
    --                   TRACE COMPTE-RENDU DEPOSE        --
    -------------------------------------------------------- 
    else if (@v_typeTrace = @EXECUTION_TACHE)
    begin
      -- Récupération de l'action de la tâche
      set @v_pos = charindex(';',@v_detail)
      if (@v_pos <> 0)
      begin
        set @v_idAction = substring(@v_detail,1,@v_pos-1)
        set @v_detail = substring(@v_detail,@v_pos+1,len(@v_detail)-@v_pos)

        -- récupération du code d'exécution de la tâche
        set @v_pos = charindex(';',@v_detail)
        if (@v_pos <> 0)
        begin
          set @v_crdExec = substring(@v_detail,1,@v_pos-1)
          if (@v_crdExec = @TACHE_OK)
          begin
            if (@v_idAction = @ACTION_PRISE)
            begin
              -- trace prise réalisée
              set @v_datePrise = @v_dateOperation
              set @v_adrPrise = @v_adrBase
            end
            else if (@v_idAction = @ACTION_DEPOSE)
            begin
              -- trace dépose réalisée
              set @v_dateDepose = @v_dateOperation
              set @v_adrDepose = @v_adrBase
            end
          end
        end
      end  
    end 
    --------------------------------------------------------
    --                   TRACE FIN MISSION                --
    -------------------------------------------------------- 
    else if (@v_typeTrace = @FIN) 
    begin
      set @v_dateEcriture=@v_dateOperation
    end
  
    -- passage à l'information mission suivante
    fetch next from  c_selectInfoMission INTO @v_dateOperation,@v_typeTrace,@v_detail,@v_idDemandeCrt,
                                              @v_idChargeCrt,@v_adrSys,@v_adrBase,@v_adrSsBase,@v_idAgvCrt
  end

  -- fermeture du curseur de sélection des informations mission
  close c_selectInfoMission
  deallocate c_selectInfoMission

  -- écriture dans la table temporaire 
  set @v_strTrace = convert(varchar(80),@v_dateEcriture,103) + ' ' + convert(varchar(80),@v_dateEcriture,108) + ','
                  + convert(varchar,@v_idMission) + ',' 
                  + isnull(@v_idDemande, '') + ','
                  + CONVERT(varchar, ISNULL(@v_idCharge, '')) + ','
                  + convert(varchar,@v_idAgv) + ','
                  + convert(varchar(80),@v_dateCreation,103) + ' ' + convert(varchar(80),@v_dateCreation,108) + ','
                  + convert(varchar(80),@v_dateAttribution,103) + ' ' + convert(varchar(80),@v_dateAttribution,108) + ','
                  + convert(varchar(80),@v_datePrise,103) + ' ' + convert(varchar(80),@v_datePrise,108) + ','
                  + convert(varchar(80),@v_dateDepose,103) + ' ' + convert(varchar(80),@v_dateDepose,108) + ','
                  + convert(varchar,@v_adrAttribution) + ','
                  + convert(varchar,@v_adrPrise) + ','
                  + convert(varchar,@v_adrDepose)+ ',5'
                                    
      
  insert into @v_trace (TMT_CHAINE) values (@v_strTrace)
  if (@@ERROR <> 0)
  begin 
    set @v_codeRetour = @CODE_KO_SQL
    break
  end
  
  -- passage à la mission suivante
  fetch next from  c_selectMission INTO @v_idMissionCrt
end


-- fermeture du curseur de sélection des mission
close c_selectMission
deallocate c_selectMission


SET NOCOUNT ON

if (@v_codeRetour = @CODE_OK)
begin
  select TMT_CHAINE from @v_trace
end
else
begin
  select NULL
end

return @v_codeRetour


SET NOCOUNT OFF


