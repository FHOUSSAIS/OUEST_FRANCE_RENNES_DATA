SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER OFF


-----------------------------------------------------------------------------------------
-- Procédure            : SPV_SETTRACEORDREAGV
-- Paramètre d'entrée	: @v_typeTrace : Type de la trace à écrire
--			  @v_dscTrace : Détail sur le type de trace
--			  @v_idOrdre : Identifiant de l'ordre agv
--			  @v_idAgv : Identifiant de l'Agv responsable de l'exécution de l'ordre
--			  @v_adrSys : Adresse système où a lieu l'action de l'ordre
--			  @v_adrBase : Adresse base où a lieu l'action de l'ordre
--			  @v_actPrimaire : Action primaire de l'ordre
--			  @v_actSecondaire : Liste des actions secondaires de l'ordre
--                                             (format 'action1;action2;...;actionn;')
-- Paramètres de sortie : Code de retour par défaut
--			    - @CODE_OK: L'operation s'est executée correctement
--			    - @CODE_KO_SQL: Une erreur SQL s'est produite lors de l'operation
--			    - @CODE_KO_PARAM : Le type de trace n'est pas connu
-- Descriptif           : Cette procédure permet d'ajouter une trace ordre agv
--
-----------------------------------------------------------------------------------------
-- Révisions											
-----------------------------------------------------------------------------------------
-- Date			: 									
-- Auteur		: 									
-- Libellé		: Création de la procédure						
-----------------------------------------------------------------------------------------
-- Date			: 18/06/2007
-- Auteur		: Cédric LE FRINGERE
-- Libellé			: Standardisation Logistic Core
-----------------------------------------------------------------------------------------

CREATE PROCEDURE [dbo].[SPV_SETTRACEORDREAGV]
	@v_typeTrace integer,
	@v_dscTrace varchar(50),
	@v_idOrdre integer,
	@v_idAgv tinyint,
	@v_adrSys bigint,
	@v_adrBase bigint,
	@v_actPrimaire integer,
	@v_actSecondaire varchar(100)
AS

IF 1 = 0
BEGIN
	-- This line will be executed if FMTONLY was initially set to ON
	SET FMTONLY OFF
	RETURN
END

-- déclaration des constantes de code retour 
declare @CODE_OK integer
declare @CODE_KO_SQL integer
declare @CODE_KO_PARAM integer

--définition des constantes de code retour 
set @CODE_OK = 0
set @CODE_KO_SQL = 13
set @CODE_KO_PARAM = 8

-- déclaration des constantes de type de trace ordre agv
declare @CREATION tinyint                 -- Création ordre
declare @CHANGE_ETAT tinyint              -- Changement d'état d'un ordre
declare @ANNULATION tinyint               -- Annulation d'un ordre
declare @FIN tinyint                      -- Fin d'un ordre
declare @DESTRUCTION tinyint		  -- Destruction ordre

-- définition des constantes de type de trace ordre
set @CREATION            = 1
set @CHANGE_ETAT         = 2
set @ANNULATION          = 5
set @FIN                 = 6
set @DESTRUCTION         = 8

--déclaration des variables
declare @v_codeRetour integer

-- initialisation des variables
set @v_codeRetour = @CODE_OK

-- controle des types
if      (@v_typeTrace<>@CREATION)
    and (@v_typeTrace<>@CHANGE_ETAT)
    and (@v_typeTrace<>@ANNULATION)
    and (@v_typeTrace<>@FIN)
    and (@v_typeTrace<>@DESTRUCTION)
begin
  set @v_codeRetour = @CODE_KO_PARAM
end


if @v_codeRetour = @CODE_OK
begin
  -- Ecriture des traces de création
  if (@v_typeTrace = @CREATION)
  begin
    insert into TRACE_ORDRE_AGV(TRO_Date,TRO_TypeTrc,TRO_IdOrdre,TRO_IdAgv)
    values (getDate(),@CREATION,@v_idOrdre,@v_idAgv)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end
  
  -- Ecriture des traces de changement d'état
  else if (@v_typeTrace = @CHANGE_ETAT)
  begin
    insert into TRACE_ORDRE_AGV(TRO_Date,TRO_TypeTrc,TRO_DscTrc,TRO_IdOrdre,TRO_IdAgv,TRO_AdrSys,TRO_AdrBase,
    TRO_ActPrimaire,TRO_ActSecondaire)
    values (getDate(),@CHANGE_ETAT,@v_dscTrace,@v_idOrdre,@v_idAgv,@v_adrSys,@v_adrBase,@v_actPrimaire,
    @v_actSecondaire)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end

  -- Ecriture des traces d'annulation ordre
  else if (@v_typeTrace = @ANNULATION)
  begin
    insert into TRACE_ORDRE_AGV(TRO_Date,TRO_TypeTrc,TRO_DscTrc,TRO_IdOrdre,TRO_IdAgv)
    values (getDate(),@ANNULATION,@v_dscTrace,@v_idOrdre,@v_idAgv)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end

  -- Ecriture des traces de fin ordre
  else if (@v_typeTrace = @FIN)
  begin
    insert into TRACE_ORDRE_AGV(TRO_Date,TRO_TypeTrc,TRO_DscTrc,TRO_IdOrdre,TRO_IdAgv)
    values (getDate(),@FIN,@v_dscTrace,@v_idOrdre,@v_idAgv)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end

  -- Ecriture des traces de destruction ordre
  else if (@v_typeTrace = @DESTRUCTION)
  begin
    insert into TRACE_ORDRE_AGV(TRO_Date,TRO_TypeTrc,TRO_IdOrdre,TRO_IdAgv)
    values (getDate(),@DESTRUCTION,@v_idOrdre,@v_idAgv)
    if @@ERROR <> 0
    begin
      set @v_codeRetour = @CODE_KO_SQL    
    end
  end
end


return @v_codeRetour 		


